import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight HTTP client for the InterTaxi Flask backend.
///
/// All calls are best-effort: if the backend is offline or unreachable the
/// methods return empty/neutral values and never throw — the driver flow and
/// the passenger UI must keep working with locally stored data.
class ApiService {
  ApiService._();

  /// Effective server address for the InterTaxi Flask backend.
  ///
  /// The backend is now deployed on Render; this is the default address used
  /// by every REST and Socket.IO call. The user can still override it (see
  /// [setCustomBaseUrl]) for local development against a PC-running Flask.

  static const String _baseUrlPrefsKey = 'backend_url';
  static String? _customBaseUrl;

  /// Deployed backend (Render) — used for HTTP and Socket.IO alike.
  static const String defaultBaseUrl = 'https://intertaxi-zarc.onrender.com';
  static String? _firebaseAuthFailure;

  static String resolvePhotoUrl(String value) {
    final path = value.trim();
    if (path.startsWith('/')) return '${_customBaseUrl ?? defaultBaseUrl}$path';
    return path;
  }

  static String _platformDefault() {
    return defaultBaseUrl;
  }

  static Future<String?> firebaseIdToken() async {
    try {
      final auth = FirebaseAuth.instance;
      // Wait for Firebase to restore the persisted Google session on cold
      // start. This observes the existing session and never starts a sign-in
      // flow or creates a second Firebase account.
      final user = auth.currentUser ??
          await auth.authStateChanges().first.timeout(
            const Duration(seconds: 8),
          );
      if (user == null) {
        _firebaseAuthFailure = 'No signed-in Firebase user was restored.';
        return null;
      }
      final token = await user.getIdToken();
      _firebaseAuthFailure = token == null || token.isEmpty
          ? 'Firebase did not return an ID token.'
          : null;
      return token;
    } catch (error) {
      _firebaseAuthFailure = error.toString();
      debugPrint('[ApiService] Could not read the current Firebase session: $error');
      return null;
    }
  }

  static Future<Map<String, String>?> _authenticatedHeaders() async {
    final token = await firebaseIdToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>?> _freshAuthenticatedHeaders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _firebaseAuthFailure = 'No signed-in Firebase user was restored.';
        return null;
      }
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        _firebaseAuthFailure = 'Firebase did not return an ID token.';
        return null;
      }
      _firebaseAuthFailure = null;
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (error) {
      _firebaseAuthFailure = error.toString();
      debugPrint('[ApiService] Could not refresh Firebase ID token: $error');
      return null;
    }
  }

  static String get _firebaseAuthErrorMessage {
    final failure = _firebaseAuthFailure ?? '';
    if (failure.contains('No signed-in Firebase user')) {
      return 'No authenticated Firebase session is available. Sign in with Google and try again.';
    }
    return 'Firebase authentication is unavailable: $failure';
  }

  /// Resolves the effective backend address: the user-configured override (if
  /// set) or the platform default. Async because the override is stored in prefs.
  static Future<String> resolveBaseUrl() async {
    if (_customBaseUrl != null) return _customBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlPrefsKey)?.trim() ?? '';
    if (saved.isNotEmpty) {
      _customBaseUrl = _normalizeUrl(saved);
      return _customBaseUrl!;
    }
    return _platformDefault();
  }

  /// Saves a custom server address (e.g. `https://intertaxi-zarc.onrender.com`).
  /// An empty value resets to the deployed default (Render).
  static Future<void> setCustomBaseUrl(String value) async {
    final trimmed = value.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      _customBaseUrl = null;
      await prefs.remove(_baseUrlPrefsKey);
      return;
    }
    final normalized = _normalizeUrl(trimmed);
    _customBaseUrl = normalized;
    await prefs.setString(_baseUrlPrefsKey, normalized);
  }

  /// Tidies up a user-typed address: adds scheme, strips trailing slash.
  static String _normalizeUrl(String value) {
    var cleaned = value.trim();
    if (!cleaned.contains('://')) {
      cleaned = 'https://$cleaned';
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Pushes a driver trip/announcement to the backend (REST) and returns the
  /// created trip map — including its REAL server id (UUID) — so callers can
  /// link the locally saved announcement to the server row and later delete
  /// it by that exact id. Returns `null` when the server is unreachable or
  /// rejects the trip.
  static Future<Map<String, dynamic>?> createTrip(
    Map<String, dynamic> payload, {
    bool returnEnvelope = false,
  }) async {
    String? requestUrl;
    String? currentUid;
    try {
      final base = await resolveBaseUrl();
      final uri = Uri.parse('$base/api/trips');
      requestUrl = uri.toString();
      // Render's free service may be asleep. Wake it first so a cold start
      // does not make a valid announcement look like a local-only save.
      try {
        await http
            .get(Uri.parse('$base/api/health'))
            .timeout(const Duration(seconds: 45));
      } catch (_) {
        // Continue with the publish request; it is the authoritative result.
      }

      // Keep the verified Firebase owner on the trip so the same signed-in
      // user can later start it.
      final headers = await _freshAuthenticatedHeaders();
      if (headers == null) {
        debugPrint(
          '[ApiService] createTrip not sent: Firebase ID token unavailable; '
          'firebaseUid=${FirebaseAuth.instance.currentUser?.uid ?? "unavailable"}; '
          'firebaseError=$_firebaseAuthFailure',
        );
        return null;
      }
      currentUid = FirebaseAuth.instance.currentUser?.uid;
      final requestBody = jsonEncode(payload);
      if (kDebugMode) {
        // TEMP DEBUG
        debugPrint('[ApiService] createTrip final JSON body: $requestBody');
      }
      debugPrint(
        '[ApiService] createTrip POST $requestUrl; '
        'firebaseUid=${currentUid ?? "unavailable"}; bearerTokenPresent=true; '
        'bodyKeys=${payload.keys.toList()}; price=${payload['price']}; '
        'availableSeats=${payload['available_seats']}',
      );
      final response = await http
          .post(
            uri,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 45));
      if (kDebugMode) {
        // TEMP DEBUG
        debugPrint(
          '[ApiService] createTrip response: url=$requestUrl; '
          'status=${response.statusCode}; body=${response.body}',
        );
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final trip = data['trip'];
          if (returnEnvelope) return data;
          if (trip is Map<String, dynamic>) return trip;
          return data;
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[ApiService] createTrip exception: url=${requestUrl ?? "unresolved"}; '
        'firebaseUid=${currentUid ?? "unavailable"}; '
        'error=$error\n$stackTrace',
      );
      // ignore — backend offline
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadTripPhotos(
    String tripId,
    File front,
    File rear,
    File side,
  ) async {
    try {
      final base = await resolveBaseUrl();
      final token = await firebaseIdToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('[ApiService] uploadTripPhotos failed: no Firebase token');
        return null;
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/api/trips/${Uri.encodeComponent(tripId)}/photos'),
      )..headers['Authorization'] = 'Bearer $token';
      request.files.addAll([
        await http.MultipartFile.fromPath(
          'front',
          front.path,
          contentType: MediaType('image', 'webp'),
        ),
        await http.MultipartFile.fromPath(
          'rear',
          rear.path,
          contentType: MediaType('image', 'webp'),
        ),
        await http.MultipartFile.fromPath(
          'side',
          side.path,
          contentType: MediaType('image', 'webp'),
        ),
      ]);
      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) {
        debugPrint(
          '[ApiService] uploadTripPhotos response: tripId=$tripId; '
          'status=${response.statusCode}; body=${response.body}',
        );
      }
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final trip = data['trip'];
      return trip is Map<String, dynamic> ? trip : data;
    } catch (error) {
      debugPrint('[ApiService] uploadTripPhotos failed: $error');
      return null;
    }
  }

  /// Pushes a driver trip/announcement to the backend (REST fallback used by
  /// the create-order flow). Returns `true` when the server accepted it.
  static Future<bool> postTrip(Map<String, dynamic> payload) async {
    return await createTrip(payload) != null;
  }

  /// Loads bookings stored for a driver so messages survive reconnects.
  static Future<List<Map<String, dynamic>>> fetchDriverBookings(
    String driverId,
  ) async {
    try {
      final base = await resolveBaseUrl();
      final uri = Uri.parse(
        '$base/api/bookings',
      ).replace(queryParameters: {'driver_id': driverId});
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bookings = data['bookings'] as List<dynamic>? ?? const [];
        return bookings.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // ignore — backend offline
    }
    return const [];
  }

  /// Returns the server-filtered earnings for the authenticated Firebase user.
  static Future<Map<String, dynamic>?> fetchDriverEarnings({
    required String period,
  }) async {
    try {
      final base = await resolveBaseUrl();
      final headers = await _authenticatedHeaders();
      if (headers == null) return null;
      final uri = Uri.parse(
        '$base/api/earnings',
      ).replace(queryParameters: {'period': period});
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Preserve a distinction between unavailable real data and zero income.
    }
    return null;
  }

  static Future<Map<String, dynamic>> startTrip({
    required String tripId,
  }) async {
    String? requestUrl;
    String? currentUid;
    try {
      final base = await resolveBaseUrl();
      final uri = Uri.parse(
        '$base/api/trips/${Uri.encodeComponent(tripId)}/start',
      );
      requestUrl = uri.toString();
      final headers = await _freshAuthenticatedHeaders();
      if (headers == null) {
        debugPrint(
          '[ApiService] startTrip not sent: no Firebase ID token; '
          'tripId=$tripId, firebaseError=$_firebaseAuthFailure',
        );
        return {'ok': false, 'error': _firebaseAuthErrorMessage};
      }
      currentUid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint(
        '[ApiService] startTrip POST $requestUrl; tripId=$tripId; '
        'firebaseUid=${currentUid ?? "unavailable"}; '
        'bearerTokenPresent=true',
      );
      // Wake the hosted service before the authenticated start request.
      try {
        await http
            .get(Uri.parse('$base/api/health'))
            .timeout(const Duration(seconds: 45));
      } catch (_) {
        // The protected start request below determines whether it is usable.
      }
      final response = await http
          .post(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 45));
      debugPrint(
        '[ApiService] startTrip response: url=$requestUrl; '
        'status=${response.statusCode}; body=${response.body}',
      );
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (error) {
        return {
          'ok': false,
          'error': 'Server returned non-JSON response '
              '(HTTP ${response.statusCode}): '
              '${response.body.isEmpty ? error.message : response.body}',
        };
      }
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final serverError = decoded['error']?.toString();
          final message = response.statusCode == 403
              ? 'You are not the driver who created this trip. If this is your trip, it may need its owner record repaired.'
              : response.statusCode == 401
                  ? 'Your sign-in expired. Please sign in again and retry.'
                  : serverError?.isNotEmpty == true
                      ? serverError!
                      : response.body;
          return {
          ...decoded,
          'ok': false,
          'error': message,
          };
        }
        return decoded;
      }
      return {
        'ok': false,
        'error': 'Unexpected server response (HTTP ${response.statusCode}): ${response.body}',
      };
    } catch (error, stackTrace) {
      debugPrint(
        '[ApiService] startTrip request exception: url=${requestUrl ?? "unresolved"}; '
        'tripId=$tripId; firebaseUid=${currentUid ?? "unavailable"}; '
        'error=$error\n$stackTrace',
      );
      return {'ok': false, 'error': 'Start trip request failed: $error'};
    }
  }

  /// Completes a server trip and records the timestamp used by earnings filters.
  static Future<List<Map<String, dynamic>>> fetchPassengerBookings(
    String passengerPhone,
  ) async {
    try {
      final base = await resolveBaseUrl();
      final uri = Uri.parse(
        '$base/api/bookings',
      ).replace(queryParameters: {'passenger_phone': passengerPhone});
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bookings = data['bookings'] as List<dynamic>? ?? const [];
        return bookings.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // ignore transient network errors
    }
    return const [];
  }

  static Future<bool> deleteAllBookings({
    String? driverId,
    String? passengerPhone,
  }) async {
    try {
      final base = await resolveBaseUrl();
      final query = <String, String>{
        if (driverId != null && driverId.isNotEmpty) 'driver_id': driverId,
        if (passengerPhone != null && passengerPhone.isNotEmpty)
          'passenger_phone': passengerPhone,
      };
      final uri = Uri.parse(
        '$base/api/bookings',
      ).replace(queryParameters: query);
      final response = await http
          .delete(uri)
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Books a trip through the reliable REST API. The backend persists the
  /// booking and broadcasts the driver notification after committing it.
  static Future<Map<String, dynamic>> createBooking({
    required String tripId,
    required String passengerName,
    required String passengerPhone,
    required int requestedSeats,
  }) async {
    try {
      final base = await resolveBaseUrl();
      // Render's free service may sleep. Wake it before sending the booking
      // request so the passenger does not time out during cold start.
      try {
        await http
            .get(Uri.parse('$base/api/health'))
            .timeout(const Duration(seconds: 45));
      } catch (_) {
        // The booking request below remains the source of truth.
      }
      final response = await http
          .post(
            Uri.parse('$base/api/bookings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'trip_id': tripId,
              'passenger_name': passengerName,
              'passenger_phone': passengerPhone,
              'requested_seats': requestedSeats,
            }),
          )
          .timeout(const Duration(seconds: 45));
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'ok': false, 'error': 'Invalid server response'};
    } catch (error) {
      return {'ok': false, 'error': 'Server connection failed: $error'};
    }
  }

  static Future<Map<String, dynamic>> decideBooking({
    required String bookingId,
    required bool approved,
  }) async {
    try {
      final base = await resolveBaseUrl();
      final headers = await _authenticatedHeaders();
      if (headers == null) {
        return {'ok': false, 'error': 'Authentication is unavailable'};
      }
      final response = await http
          .post(
            Uri.parse('$base/api/bookings/$bookingId/decision'),
            headers: headers,
            body: jsonEncode({'decision': approved ? 'approved' : 'rejected'}),
          )
          .timeout(const Duration(seconds: 45));
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'ok': false, 'error': 'Invalid server response'};
    } catch (error) {
      return {'ok': false, 'error': 'Server connection failed: $error'};
    }
  }

  static Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required String passengerPhone,
    required int rating,
    required String text,
  }) async {
    try {
      final base = await resolveBaseUrl();
      final response = await http
          .post(
            Uri.parse('$base/api/reviews'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'booking_id': bookingId,
              'passenger_phone': passengerPhone,
              'rating': rating,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'ok': false, 'error': 'Invalid server response'};
    } catch (error) {
      return {'ok': false, 'error': 'Server connection failed: $error'};
    }
  }

  /// Fetches trips from the backend, optionally filtered by the EXACT route.
  ///
  /// When [from] / [to] are provided they are sent as `?from=...&to=...`
  /// query parameters and the server returns ONLY trips created for that
  /// exact route (from_location + to_location), so the passenger main screen
  /// never displays trips for another route. Returns an empty list on any
  /// failure so callers never have to handle exceptions.
  static Future<List<Map<String, dynamic>>> fetchTrips({
    String? from,
    String? to,
  }) async {
    try {
      final base = await resolveBaseUrl();
      final f = from?.trim();
      final t = to?.trim();
      final uri = Uri.parse('$base/api/trips').replace(
        queryParameters: {
          if (f != null && f.isNotEmpty) 'from': f,
          if (t != null && t.isNotEmpty) 'to': t,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final trips = data['trips'] as List<dynamic>? ?? const [];
        return trips.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // ignore — backend offline
    }
    return const [];
  }

  /// Deletes a trip on the backend via REST: `http.delete('$base/api/trips/$tripId')`.
  ///
  /// This is the PRIMARY delete path used when the driver taps delete — it
  /// guarantees the row is removed from the server database (Render), and
  /// the server then broadcasts `trip_deleted` to every connected client.
  /// Returns `true` when the server confirmed the deletion (200/204) or
  /// reports the trip as already gone (404) — both mean the server DB is in
  /// sync. Returns `false` only when the server could not be reached.
  static Future<bool> deleteTrip(String tripId) async =>
      (await deleteTripWithResult(tripId))['ok'] == true;

  /// Deletes a trip and exposes diagnostics to the caller. HTTP 404 means the
  /// announcement is already absent, so it is treated as an idempotent success.
  static Future<Map<String, dynamic>> deleteTripWithResult(String tripId) async {
    String url = 'unresolved';
    try {
      final base = await resolveBaseUrl();
      final uri = Uri.parse('$base/api/trips/${Uri.encodeComponent(tripId)}');
      url = uri.toString();
      Map<String, dynamic> lastFailure = {
        'ok': false,
        'error': 'Could not reach the server',
      };

      for (var attempt = 1; attempt <= 2; attempt++) {
        final headers = await _freshAuthenticatedHeaders();
        if (headers == null) {
          final error = _firebaseAuthErrorMessage;
          debugPrint(
            '[ApiService] method=DELETE url=$url attempt=$attempt '
            'status=not_sent body=$error bearerTokenPresent=false',
          );
          lastFailure = {'ok': false, 'error': error};
          continue;
        }
        try {
          final response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          final bearerTokenPresent =
              headers['Authorization']?.startsWith('Bearer ') == true;
          debugPrint(
            '[ApiService] method=DELETE url=$url attempt=$attempt '
            'status=${response.statusCode} body=${response.body} '
            'bearerTokenPresent=$bearerTokenPresent',
          );
          if (response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 404) {
            return {'ok': true, 'status': response.statusCode};
          }
          dynamic decoded;
          try {
            decoded = jsonDecode(response.body);
          } on FormatException {
            decoded = null;
          }
          final message = decoded is Map<String, dynamic>
              ? decoded['error']?.toString()
              : null;
          lastFailure = {
            'ok': false,
            'error': message?.isNotEmpty == true
                ? message!
                : 'Announcement deletion failed (HTTP ${response.statusCode}): ${response.body}',
            'status': response.statusCode,
            'body': response.body,
          };
        } catch (error, stackTrace) {
          debugPrint(
            '[ApiService] method=DELETE url=$url attempt=$attempt '
            'status=exception body=$error bearerTokenPresent=true\n$stackTrace',
          );
          lastFailure = {'ok': false, 'error': 'Could not reach the server: $error'};
        }
      }
      return lastFailure;
    } catch (error, stackTrace) {
      debugPrint(
        '[ApiService] method=DELETE url=$url status=exception body=$error\n$stackTrace',
      );
      return {'ok': false, 'error': 'Could not reach the server: $error'};
    }
  }
}
