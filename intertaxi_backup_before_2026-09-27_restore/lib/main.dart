import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
// Firebase + Google Sign-In authentication (email / profile / openid).
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'constants/light_glass_theme.dart';
import 'screens/passenger_home_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/server_settings_screen.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/tts_service.dart';
import 'widgets/intertaxi_logo.dart';
import 'widgets/light_glass_widgets.dart';
import 'widgets/animated_bottom_navigation.dart';

const String _appSessionVersion = 'intertaxi_session_v2';

class _AnimatedCarLoading extends StatefulWidget {
  final Color color;

  const _AnimatedCarLoading({this.color = Colors.white});

  @override
  State<_AnimatedCarLoading> createState() => _AnimatedCarLoadingState();
}

class _AnimatedCarLoadingState extends State<_AnimatedCarLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Icon(
        AppIcons.directions_car_rounded,
        color: widget.color,
        size: 22,
      ),
      builder: (context, child) =>
          Transform.rotate(angle: _controller.value * 6.28318, child: child),
    );
  }
}

class CarBrand {
  final String name;
  final String logoAsset;

  const CarBrand(this.name, this.logoAsset);
}

/// The only vehicle makes supported by InterTaxi driver profiles.
const List<CarBrand> supportedCarBrands = [
  CarBrand('Toyota', 'assets/logos/cars/toyota-logo.svg'),
  CarBrand('Mercedes-Benz', 'assets/logos/cars/mercedes-benz-logo.svg'),
  CarBrand('BMW', 'assets/logos/cars/bmw-logo.svg'),
  CarBrand('Hyundai', 'assets/logos/cars/hyundai-logo.svg'),
  CarBrand('Kia', 'assets/logos/cars/kia-logo.svg'),
  CarBrand('Lexus', 'assets/logos/cars/lexus-logo.png'),
  CarBrand('Opel', 'assets/logos/cars/opel-logo.svg'),
  CarBrand('Chevrolet', 'assets/logos/cars/chevrolet-logo.png'),
  CarBrand('Daewoo', 'assets/logos/cars/daewoo-logo.png'),
  CarBrand('Honda', 'assets/logos/cars/honda-logo.png'),
  CarBrand('Nissan', 'assets/logos/cars/nissan-logo.svg'),
  CarBrand('Mitsubishi', 'assets/logos/cars/mitsubishi-logo.svg'),
  CarBrand('Ford', 'assets/logos/cars/ford-logo.png'),
  CarBrand('Volkswagen', 'assets/logos/cars/volkswagen-logo.svg'),
  CarBrand('Audi', 'assets/logos/cars/audi-logo.svg'),
  CarBrand('Tesla', 'assets/logos/cars/tesla-logo.svg'),
  CarBrand('BYD', 'assets/logos/cars/byd-logo.svg'),
  CarBrand('Chery', 'assets/logos/cars/chery-logo.png'),
  CarBrand('Geely', 'assets/logos/cars/geely-logo.svg'),
  CarBrand('Haval', 'assets/logos/cars/haval-logo.png'),
  CarBrand('Jetour', 'assets/logos/cars/jetour-logo.svg'),
  CarBrand('Changan', 'assets/logos/cars/changan-logo.png'),
  CarBrand('Li Auto', 'assets/logos/cars/li-auto-logo.svg'),
  CarBrand('Zeekr', 'assets/logos/cars/zeekr-logo.png'),
  CarBrand('AITO', 'assets/logos/cars/aito-logo.svg'),
  CarBrand('Hongqi', 'assets/logos/cars/hongqi-logo.png'),
  CarBrand('GAC', 'assets/logos/cars/gac-logo.png'),
  CarBrand('Great Wall', 'assets/logos/cars/great-wall-logo.png'),
  CarBrand('FAW', 'assets/logos/cars/faw-logo.svg'),
  CarBrand('JAC', 'assets/logos/cars/jac-logo.png'),
  CarBrand('Dongfeng', 'assets/logos/cars/dongfeng-logo.png'),
  CarBrand('Exeed', 'assets/logos/cars/exeed-logo.png'),
  CarBrand('NIO', 'assets/logos/cars/nio-logo.png'),
  CarBrand('XPeng', 'assets/logos/cars/xpeng-logo.png'),
  CarBrand('Mazda', 'assets/logos/cars/mazda-logo.svg'),
  CarBrand('Subaru', 'assets/logos/cars/subaru-logo.png'),
  CarBrand('Suzuki', 'assets/logos/cars/suzuki-logo.svg'),
  CarBrand('Isuzu', 'assets/logos/cars/isuzu-logo.svg'),
  CarBrand('Land Rover', 'assets/logos/cars/land-rover-logo.svg'),
  CarBrand('Range Rover', 'assets/logos/cars/range-rover-logo.svg'),
  CarBrand('Porsche', 'assets/logos/cars/porsche-logo.svg'),
  CarBrand('Volvo', 'assets/logos/cars/volvo-logo.svg'),
  CarBrand('Skoda', 'assets/logos/cars/skoda-logo.svg'),
  CarBrand('Renault', 'assets/logos/cars/renault-logo.svg'),
  CarBrand('Peugeot', 'assets/logos/cars/peugeot-logo.svg'),
  CarBrand('CitroГ«n', 'assets/logos/cars/citroen-logo.svg'),
  CarBrand('Jeep', 'assets/logos/cars/jeep-logo.svg'),
  CarBrand('Cadillac', 'assets/logos/cars/cadillac-logo.png'),
  CarBrand('Infiniti', 'assets/logos/cars/infiniti-logo.svg'),
  CarBrand('Genesis', 'assets/logos/cars/genesis-logo.svg'),
];

const Map<String, LatLng> taxiLocationCoordinates = {
  'Душанбе': LatLng(38.5598, 68.7870),
  'Кӯлоб': LatLng(37.9146, 69.7847),
  'Восеъ': LatLng(37.8042, 69.6442),
  'Хуҷанд': LatLng(40.2826, 69.6222),
  'Бохтар': LatLng(37.8368, 68.7802),
  'Канибодом': LatLng(40.2833, 70.4333),
  'Исфара': LatLng(40.1228, 70.5983),
  'Файзобод': LatLng(38.5473, 69.2132),
  'Турсунзода': LatLng(38.5126, 68.2312),
  'Панҷакент': LatLng(39.4952, 67.6093),
  'Истаравшан': LatLng(39.9142, 69.0033),
  'Ваҳдат': LatLng(38.5563, 69.0135),
  'ТІРёСЃРѕСЂ': LatLng(38.5256, 68.5512),
  'РҐРѕСЂСѓТ“': LatLng(37.4893, 71.5532),
  'Данғара': LatLng(38.0983, 69.3384),
  'РЇРІРѕРЅ': LatLng(38.3090, 69.0558),
  'Рашт': LatLng(39.0286, 70.3733),
  'Шаҳритус': LatLng(37.2625, 68.1381),
  'Қубодиён': LatLng(37.4308, 68.0839),
  'Ҷаббор Расулов': LatLng(40.2458, 69.5000),
  'Спитамен': LatLng(40.2208, 69.3400),
  'Дарвоз': LatLng(38.4578, 70.7816),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes Firebase so `google_sign_in` can resolve the OAuth web client
  // (`default_web_client_id`) generated from android/app/google-services.json.
  // Best-effort: the app keeps working offline if initialization fails.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore вЂ” Google Sign-In still works for basic profile scopes.
  }
  runApp(const InterTaxiApp());
}

/* class InterTaxiApp extends StatelessWidget {
  const InterTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterTaxi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isOnline
                                          ? const Color(0xFF22C55E)
                                          : Colors.grey,
                                      width: 3,
                                    ),
                                    image: _profileImage != null
                                        ? DecorationImage(
                                            image: MemoryImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profileImage == null
                                      ? const Icon(
                                          AppIcons.person_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      AppIcons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 42),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['full_name'] ?? 'Ронанда',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.24,
                                          ),
                                        ),
                                      ),
                                      child: Text(AppLocalizations.translate('Ронанда'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          AppIcons.phone_rounded,
                                          size: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            data['phone'] ?? 'вЂ”',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withValues(
                                                alpha: 0.82,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _openSettingsScreen,
                              tooltip: AppLocalizations.translate('Танзимот'),
                              icon: const Icon(
                                AppIcons.settings_rounded,
                                size: 23,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                      'InterTaxi',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your ride, your way',
                                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 40),
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF0066FF),
                                          ),
                                        ),
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your ride, your way',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0066FF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

*/

class InterTaxiApp extends StatelessWidget {
  const InterTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterTaxi',
      locale: const Locale('tg'),
      supportedLocales: const [Locale('tg')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: buildLightGlassTheme().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // No artificial splash delay - read the saved session immediately
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final name = prefs.getString('user_name');
    final phone = prefs.getString('user_phone');
    final role = prefs.getString('user_role');

    if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) {
      if (role == 'driver') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                DriverHomeScreen(driverName: name, driverPhone: phone),
          ),
        );
        return;
      } else if (role == 'passenger') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                PassengerHomeScreen(passengerName: name, passengerPhone: phone),
          ),
        );
        return;
      }

      // The Google identity is already verified but the registration was not
      // finished (no role selected yet) -> continue with the registration form.
      _navigateToRegistration(name);
      return;
    }

    // No saved user session -> verify the identity with Google first.
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
    );
  }

  /// Opens the registration form (name, surname, gender, birth year, phone),
  /// optionally pre-filled with the name of the verified Google account.
  void _navigateToRegistration(String? fullName) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(initialFullName: fullName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InterTaxiLogo(size: 120, showTagline: true),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google sign-in gate.
///
/// Shown to users who do not have a saved session yet. It wraps the
/// `google_sign_in` plugin (Android / iOS / macOS / Web): the user picks their
/// Google account in the native chooser and, on success, the verified identity
/// is stored in SharedPreferences before continuing into the app.
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  /// OpenID Connect / profile scopes requested during sign-in.
  static const List<String> _scopes = <String>['email', 'profile', 'openid'];

  /// Optional OAuth "web application" client id of the Firebase project. When
  /// provided (for example via
  /// `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...`) the Android flow also
  /// returns an ID token a backend can verify. When empty, the plugin falls
  /// back to the web client that the google-services Gradle plugin generates
  /// from `android/app/google-services.json` (`default_web_client_id`).
  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: String.fromEnvironment(
      'GOOGLE_SIGN_IN_CLIENT_ID',
      defaultValue: '',
    ),
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  bool _isLoading = false;
  String? _errorMessage;

  /// Opens the Google account chooser and stores the verified identity.
  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Returns null when the user closes the chooser without picking an
      // account; that is not an error, so nothing is shown in that case.
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null || !mounted) return;

      // The ID / access tokens allow a backend to verify the account. A
      // failure here must not block the user from continuing into the app.
      GoogleSignInAuthentication? authentication;
      try {
        authentication = await account.authentication;
      } catch (_) {
        authentication = null;
      }

      await _saveSession(account, authentication);
      if (!mounted) return;

      final String displayName = account.displayName ?? account.email;
      await _navigateToMainScreen(displayName, account.email);
    } catch (e) {
      if (!mounted) return;
      final bool userCanceled =
          e is PlatformException && e.code == GoogleSignIn.kSignInCanceledError;
      if (userCanceled) return;

      final String message = _errorMessageFor(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.translate(message))),
      );
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Persists the verified Google identity in the app session so the rest of
  /// the app (and the backend) can rely on it.
  Future<void> _saveSession(
    GoogleSignInAccount account,
    GoogleSignInAuthentication? authentication,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = account.displayName ?? account.email;

    await prefs.setString('app_session_version', _appSessionVersion);
    await prefs.setString('user_name', displayName);
    // The rest of the app keys sessions on "user_phone", so the verified
    // Google e-mail is stored there as a stable account identifier. It is
    // replaced by the real phone number when the registration form is saved.
    await prefs.setString('user_phone', account.email);
    await prefs.setString('user_email', account.email);
    await prefs.setString('user_google_id', account.id);
    if (account.photoUrl != null) {
      await prefs.setString('user_avatar_url', account.photoUrl!);
    }
    if (authentication != null) {
      if (authentication.idToken != null) {
        await prefs.setString('user_auth_id_token', authentication.idToken!);
      }
      if (authentication.accessToken != null) {
        await prefs.setString(
          'user_auth_access_token',
          authentication.accessToken!,
        );
      }
    }
    if (account.serverAuthCode != null) {
      await prefs.setString('user_auth_server_code', account.serverAuthCode!);
    }
  }

  /// Routes to the right screen after a successful Google login: the driver or
  /// passenger home screen when a role is already saved, otherwise the
  /// registration form for first-time users.
  Future<void> _navigateToMainScreen(
    String userName,
    String userIdentifier,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    if (!mounted) return;

    if (role == 'driver') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DriverHomeScreen(
            driverName: userName,
            driverPhone: userIdentifier,
          ),
        ),
      );
    } else if (role == 'passenger') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PassengerHomeScreen(
            passengerName: userName,
            passengerPhone: userIdentifier,
          ),
        ),
      );
    } else {
      // First-time user: finish the registration form (name, surname, gender,
      // birth year, phone). The role is chosen on the next screen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(initialFullName: userName),
        ),
      );
    }
  }

  /// Human readable (Tajik) message for the plugin's platform failures.
  String _errorMessageFor(Object error) {
    if (error is PlatformException &&
        error.code == GoogleSignIn.kNetworkError) {
      return AppLocalizations.translate(
        'Иттисоли интернет қатъ шуд. Лутфан, пайвасти шабакаро тафтиш кунед ва дубора кӯшиш кунед.',
      );
    }
    if (error is PlatformException &&
        error.code == GoogleSignIn.kSignInFailedError) {
      return AppLocalizations.translate(
        'Ворид шудан ба исоби Google ноком анҷом ёфт. Лутфан, дубора кӯшиш кунед.',
      );
    }
    return AppLocalizations.translate(
      'Хато ҳангоми ворид шудан ба ҳисоби Google рух дод. Лутфан, дубора кӯшиш кунед.',
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: LightGlassColors.textPrimary,
          disabledBackgroundColor: Colors.white,
          side: const BorderSide(
            color: LightGlassColors.glassBorderSubtle,
            width: 1.5,
          ),
          elevation: 2,
          shadowColor: LightGlassColors.primaryBlue.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const _AnimatedCarLoading(color: LightGlassColors.primaryBlue),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.translate(
                  'Лутфан, интизор бошед...',
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: LightGlassColors.textPrimary,
                ),
              ),
            ] else ...[
              const GoogleLogo(size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.translate('Бо Google идома диҳед'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LightGlassColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LightGlassCard(
                padding: const EdgeInsets.all(28),
                radius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/icon.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'InterTaxi',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: LightGlassColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.translate('Ворид шудан'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: LightGlassColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.translate(
                        'Хуш омадед ба InterTaxi! Барои бехатарӣ ва идома додан, ба ҳисоби Google-и худ ворид шавед.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: LightGlassColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildGoogleButton(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: LightGlassColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.translate(
                        'Бо идома додан шумо ба шартҳои хизматрасонӣ розӣ мешавед.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: LightGlassColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the classic Google "G" mark: a blue circle with the four brand
/// color bars and a white "G", drawn entirely with Flutter widgets so no
/// external image asset is required.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: _blue, shape: BoxShape.circle),
          ),
          // Four stacked brand-color bars on the left side of the "G".
          Positioned(
            left: size * 0.14,
            top: size * 0.22,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBar(_blue),
                SizedBox(height: size * 0.012),
                _buildBar(_red),
                SizedBox(height: size * 0.012),
                _buildBar(_yellow),
                SizedBox(height: size * 0.012),
                _buildBar(_green),
              ],
            ),
          ),
          // White "G" letter.
          Positioned(
            left: size * 0.36,
            top: size * 0.10,
            child: Text(
              'G',
              style: TextStyle(
                fontSize: size * 0.78,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(Color color) {
    return Container(
      width: size * 0.22,
      height: size * 0.095,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.02),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  /// Optional full name obtained from the verified Google account, used to
  /// pre-fill the first name / surname fields (e.g. "Али Раҳимов").
  final String? initialFullName;

  const RegistrationScreen({super.key, this.initialFullName});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  bool _isLoading = false;
  String? _passengerName;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // Pre-fill the name fields with the verified Google account name.
    final fullName = widget.initialFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty)
      return AppLocalizations.translate('Номро ворид кунед');
    if (value.length < 2)
      return AppLocalizations.translate(
        'Ном бояд на камтар аз 2 ҳарф бошад',
      );
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty)
      return AppLocalizations.translate('Насабро ворид кунед');
    if (value.length < 2)
      return AppLocalizations.translate(
        'Насаб бояд на камтар аз 2 ҳарф бошад',
      );
    return null;
  }

  String? _validateBirthYear(String? value) {
    if (value == null || value.isEmpty)
      return AppLocalizations.translate(
        'Соли таваллудро ворид кунед',
      );
    final year = int.tryParse(value);
    if (year == null)
      return AppLocalizations.translate(
        'Соли таваллуд бояд рақам бошад',
      );
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear)
      return AppLocalizations.translate(
        'Соли таваллуд нодуруст аст',
      );
    final age = currentYear - year;
    if (age < 18)
      return AppLocalizations.translate(
        'Шумо бояд на камтар аз 18 сол дошта бошед',
      );
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty)
      return AppLocalizations.translate(
        'Рақами телефонро ворид кунед',
      );
    if (value.length < 9) {
      return AppLocalizations.translate(
        'Рақами телефон бояд на камтар аз 9 рақам бошад',
      );
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveUserBasicInfo(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthYear = _birthYearController.text.trim();

    await prefs.setString('app_session_version', _appSessionVersion);
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_first_name', firstName);
    await prefs.setString('user_last_name', lastName);
    await prefs.setString('user_birth_year', birthYear);
    await prefs.setString('user_gender', _selectedGender!);
    if (_avatarBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final photo = File(
        '${directory.path}${Platform.pathSeparator}intertaxi_profile.jpg',
      );
      await photo.writeAsBytes(_avatarBytes!, flush: true);
      await prefs.setString('user_avatar_path', photo.path);
    }
  }

  void _handleSubmit() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Ҷинсро интихоб кунед',
            ),
          ),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _passengerName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      });
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          setState(() => _isLoading = false);
          await _saveUserBasicInfo(_passengerName!, _phoneController.text);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RoleSelectionScreen(
                passengerName: _passengerName!,
                passengerPhone: _phoneController.text,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Profile Photo
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: LightGlassColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LightGlassColors.primaryBlue.withValues(
                                  alpha: 0.25,
                                ),
                                width: 1.5,
                              ),
                              image: _avatarBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_avatarBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _avatarBytes == null
                                ? Icon(
                                    AppIcons.person,
                                    size: 50,
                                    color: LightGlassColors.primaryBlue,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: LightGlassColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                AppIcons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      AppLocalizations.translate(
                        'Акси худро илова кунед',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.translate(
                      'Хуш омадед ба InterTaxi',
                    ),
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: LightGlassColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.translate(
                      'Барои истифодаи хизматрасониҳо, маълумоти худро ворид кунед',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: LightGlassColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _firstNameController,
                    validator: _validateFirstName,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LightGlassColors.surfaceTint,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.glassBorderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.focus,
                          width: 1.5,
                        ),
                      ),
                      labelText: AppLocalizations.translate('РќРѕРј'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(LightGlassRadius.field),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    validator: _validateLastName,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LightGlassColors.surfaceTint,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.glassBorderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.focus,
                          width: 1.5,
                        ),
                      ),
                      labelText: AppLocalizations.translate('Насаб'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(LightGlassRadius.field),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LightGlassColors.surfaceTint,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.glassBorderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.focus,
                          width: 1.5,
                        ),
                      ),
                      labelText: AppLocalizations.translate('Ҷинс'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(LightGlassRadius.field),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Мард',
                        child: Text(AppLocalizations.translate('Мард')),
                      ),
                      DropdownMenuItem(
                        value: 'Зан',
                        child: Text(AppLocalizations.translate('Зан')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birthYearController,
                    validator: _validateBirthYear,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LightGlassColors.surfaceTint,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.glassBorderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.focus,
                          width: 1.5,
                        ),
                      ),
                      labelText: AppLocalizations.translate(
                        'Соли таваллуд',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(LightGlassRadius.field),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LightGlassColors.surfaceTint,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.glassBorderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                        borderSide: const BorderSide(
                          color: LightGlassColors.focus,
                          width: 1.5,
                        ),
                      ),
                      labelText: AppLocalizations.translate(
                        'Рақами телефон',
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LightGlassColors.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            LightGlassRadius.button,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const _AnimatedCarLoading()
                          : Text(
                              AppLocalizations.translate(
                                'Идома додан',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const RoleSelectionScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  void _handleRoleSelection(String role) {
    setState(() => _selectedRole = role);
  }

  void _handleContinue() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final fullName = widget.passengerName.trim();
      final nameParts = fullName.split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      await prefs.setString('app_session_version', _appSessionVersion);
      await prefs.setString('user_role', _selectedRole!);
      await prefs.setString('user_name', widget.passengerName);
      await prefs.setString('user_phone', widget.passengerPhone);
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);

      setState(() => _isLoading = false);
      if (_selectedRole == 'passenger') {
        // Computed ONCE here (not inside the builder) so the key is stable
        // for the lifetime of this route while still being unique per entry.
        final passengerSessionKey = ValueKey(
          'passenger-home-${widget.passengerPhone}-'
          '${DateTime.now().millisecondsSinceEpoch}',
        );
        // Remove the whole previous stack (registration, role selection, any
        // leftover screens) so the passenger home screen is always the root
        // of a fresh session вЂ” nothing stale can sit below or around it.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PassengerHomeScreen(
              // Session-scoped key: guarantees a brand-new State on every
              // entry into the passenger section (no route/search caches
              // carried over from a previous session).
              key: passengerSessionKey,
              passengerName: widget.passengerName,
              passengerPhone: widget.passengerPhone,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverRegistrationScreen(
              passengerName: widget.passengerName,
              passengerPhone: widget.passengerPhone,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.translate('Шумо кӣ ҳастед?'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: LightGlassColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRoleCard(
                        title: AppLocalizations.translate('РњСѓСЃРѕС„РёСЂ'),
                        description:
                            'Ман мехоҳам бо таксӣ сафар кунам',
                        icon: AppIcons.person,
                        isSelected: _selectedRole == 'passenger',
                        onTap: () => _handleRoleSelection('passenger'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        title: AppLocalizations.translate('Ронанда'),
                        description:
                            'Ман мехоҳам ҳамчун ронанда кор кунам',
                        icon: AppIcons.directions_car,
                        isSelected: _selectedRole == 'driver',
                        onTap: () => _handleRoleSelection('driver'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedRole == null
                        ? null
                        : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LightGlassColors.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.button,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const _AnimatedCarLoading()
                        : Text(
                            AppLocalizations.translate('Идома додан'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? LightGlassColors.lightBlue
            : LightGlassColors.surface,
        borderRadius: BorderRadius.circular(LightGlassRadius.card),
        border: Border.all(
          color: isSelected
              ? LightGlassColors.primaryBlue
              : LightGlassColors.glassBorderSubtle,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: LightGlassColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LightGlassRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 40, color: LightGlassColors.primaryBlue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LightGlassColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: LightGlassColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PassengerTripScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const PassengerTripScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  String? _selectedStartLocation;
  String? _selectedDestination;
  bool _isLoading = false;

  final List<String> _locations = [
    'Душанбе',
    'Кӯлоб',
    'Восеъ',
    'Хуҷанд',
    'Бохтар',
    'Канибодом',
    'Исфара',
    'Файзобод',
    'Турсунзода',
    'Панҷакент',
    'Истаравшан',
    'Ваҳдат',
    'ТІРёСЃРѕСЂ',
    'РҐРѕСЂСѓТ“',
    'Данғара',
    'РЇРІРѕРЅ',
    'Рашт',
    'Шаҳритус',
    'Қубодиён',
    'Ҷаббор Расулов',
    'Спитамен',
    'Дарвоз',
  ];

  void _handleSearch() async {
    if (_selectedStartLocation == null || _selectedDestination == null) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate to order details with passenger info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            fromLocation: _selectedStartLocation!,
            toLocation: _selectedDestination!,
            price: '150 СЃРѕРјРѕРЅУЈ',
            duration: '2 соат 30 дақиқа',
            seats: 3,
            passengerPhone: widget.passengerPhone,
            passengerName: widget.passengerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('РњСѓСЃРѕС„РёСЂ')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                AppLocalizations.translate(
                  'Хуш омадед, мусофир!',
                ),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.translate(
                  'Биёед саёҳати худро оғоз кунем',
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              _buildLocationCard(
                title: AppLocalizations.translate(
                  'Аз куҷо меравед?',
                ),
                placeholder: 'Ҷойи оғозро интихоб кунед',
                selectedLocation: _selectedStartLocation,
                icon: AppIcons.trip_origin,
                onTap: () async {
                  final selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(
                        title: AppLocalizations.translate(
                          'Аз куҷо меравед?',
                        ),
                        locations: _locations,
                        selectedLocation: _selectedStartLocation,
                      ),
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedStartLocation = selected);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildLocationCard(
                title: AppLocalizations.translate(
                  'Ба куҷо рафтан мехоҳед?',
                ),
                placeholder:
                    'Макони таъинотро интихоб кунед',
                selectedLocation: _selectedDestination,
                icon: AppIcons.location_on,
                onTap: () async {
                  final selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(
                        title: AppLocalizations.translate(
                          'Ба куҷо рафтан мехоҳед?',
                        ),
                        locations: _locations,
                        selectedLocation: _selectedDestination,
                      ),
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedDestination = selected);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ||
                          _selectedStartLocation == null ||
                          _selectedDestination == null
                      ? null
                      : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.translate(
                            'Ҷустуҷӯи мошин',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String placeholder,
    required String? selectedLocation,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedLocation != null
                ? const Color(0xFF0066FF)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: selectedLocation != null
                  ? const Color(0xFF0066FF)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedLocation ?? placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedLocation != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selectedLocation != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final List<String> locations;
  final String? selectedLocation;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    required this.locations,
    this.selectedLocation,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredLocations = widget.locations
        .where((location) => location.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      appBar: AppBar(
        title: Text(AppLocalizations.translate(widget.title)),
        backgroundColor: Colors.transparent,
        foregroundColor: LightGlassColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppLocalizations.translate(
                  'Ҷустуҷӯи шаҳр...',
                ),
                prefixIcon: const Icon(AppIcons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(AppIcons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4EAF4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF0066FF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredLocations.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.translate('Шаҳр ёфт нашуд'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final isSelected = widget.selectedLocation == location;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.98, end: 1),
                          duration: const Duration(milliseconds: 220),
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, location),
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEAF2FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFFE2E8F2),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A173B73),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0066FF,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        AppIcons.location_on_rounded,
                                        size: 19,
                                        color: Color(0xFF0066FF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.translate(location),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0066FF)
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? AppIcons.check_circle_rounded
                                          : AppIcons.chevron_right_rounded,
                                      color: isSelected
                                          ? const Color(0xFF0066FF)
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CarBrandSelectionScreen extends StatelessWidget {
  final List<CarBrand> brands;
  final String? selectedBrand;

  const CarBrandSelectionScreen({
    super.key,
    required this.brands,
    this.selectedBrand,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Маркаи мошин')),
        backgroundColor: Colors.transparent,
        foregroundColor: LightGlassColors.textPrimary,
        elevation: 0,
      ),
      body: LightGlassBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 150)
                .floor()
                .clamp(2, 4)
                .toInt();
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final isSelected = selectedBrand == brand.name;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, brand.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LightGlassColors.lightBlue
                          : LightGlassColors.surface,
                      borderRadius: BorderRadius.circular(
                        LightGlassRadius.card,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? LightGlassColors.primaryBlue
                            : LightGlassColors.glassBorderSubtle,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: brand.logoAsset.endsWith('.svg')
                              ? SvgPicture.asset(
                                  brand.logoAsset,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  brand.logoAsset,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            brand.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: LightGlassColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            AppIcons.check_circle,
                            color: LightGlassColors.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CarColorSelectionScreen extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;

  const CarColorSelectionScreen({
    super.key,
    required this.colors,
    this.selectedColor,
  });

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'Сабз':
        return Colors.green;
      case 'Сафед':
        return Colors.white;
      case 'РЎРёС‘Ті':
        return Colors.black;
      case 'РЎСѓСЂС…':
        return Colors.red;
      case 'Кабуд':
        return Colors.blue;
      case 'Зард':
        return Colors.yellow;
      case 'Нилӯфар':
        return Colors.purple;
      case 'Беж':
        return Colors.brown;
      case 'Кул':
        return Colors.grey;
      case 'Тилоӣ':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Ранги мошин')),
        backgroundColor: Colors.transparent,
        foregroundColor: LightGlassColors.textPrimary,
        elevation: 0,
      ),
      body: LightGlassBackground(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final isSelected = selectedColor == color;
            final colorValue = _getColorFromName(color);

            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? LightGlassColors.lightBlue
                      : LightGlassColors.surface,
                  borderRadius: BorderRadius.circular(LightGlassRadius.card),
                  border: Border.all(
                    color: isSelected
                        ? LightGlassColors.primaryBlue
                        : LightGlassColors.glassBorderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Actual color circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        color,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: LightGlassColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        AppIcons.check_circle,
                        color: LightGlassColors.primaryBlue,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DriverRegistrationScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const DriverRegistrationScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class CreateOrderScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const CreateOrderScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  int _seats = 3;
  bool _isLoading = false;
  DateTime? _departureTime;
  String? _selectedFromLocation;
  String? _selectedToLocation;
  late final AnimationController _publishAnimationController;

  String get _driverName => widget.driverName;
  String get _driverPhone => widget.driverPhone;

  final List<String> _allLocations = [
    'Душанбе',
    'Кӯлоб',
    'Восеъ',
    'Хуҷанд',
    'Бохтар',
    'Канибодом',
    'Исфара',
    'Файзобод',
    'Турсунзода',
    'Панҷакент',
    'Истаравшан',
    'Ваҳдат',
    'ТІРёСЃРѕСЂ',
    'РҐРѕСЂСѓТ“',
    'Данғара',
    'РЇРІРѕРЅ',
    'Рашт',
    'Шаҳритус',
    'Қубодиён',
    'Ҷаббор Расулов',
    'Спитамен',
    'Дарвоз',
  ];

  @override
  void dispose() {
    _publishAnimationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _publishAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _selectDepartureTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(
        () => _departureTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  static const Map<String, LatLng> _cityCoordinates = {
    'Душанбе': LatLng(38.5598, 68.7870),
    'Кӯлоб': LatLng(37.9146, 69.7847),
    'Восеъ': LatLng(37.8042, 69.6442),
    'Хуҷанд': LatLng(40.2826, 69.6222),
    'Бохтар': LatLng(37.8368, 68.7802),
    'Канибодом': LatLng(40.2833, 70.4333),
    'Исфара': LatLng(40.1228, 70.5983),
    'Файзобод': LatLng(38.5473, 69.2132),
    'Турсунзода': LatLng(38.5126, 68.2312),
    'Панҷакент': LatLng(39.4952, 67.6093),
    'Истаравшан': LatLng(39.9142, 69.0033),
    'Ваҳдат': LatLng(38.5563, 69.0135),
    'ТІРёСЃРѕСЂ': LatLng(38.5256, 68.5512),
    'РҐРѕСЂСѓТ“': LatLng(37.4893, 71.5532),
    'Данғара': LatLng(38.0983, 69.3384),
    'РЇРІРѕРЅ': LatLng(38.3090, 69.0558),
    'Рашт': LatLng(39.0286, 70.3733),
    'Шаҳритус': LatLng(37.2625, 68.1381),
    'Қубодиён': LatLng(37.4308, 68.0839),
    'Ҷаббор Расулов': LatLng(40.2458, 69.5000),
    'Спитамен': LatLng(40.2208, 69.3400),
    'Дарвоз': LatLng(38.4578, 70.7816),
  };

  Future<int> _calculateDurationMinutes() async {
    final from = _cityCoordinates[_selectedFromLocation];
    final to = _cityCoordinates[_selectedToLocation];
    if (from == null || to == null) return 0;
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        {'overview': 'false'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        final seconds = routes?.isNotEmpty == true
            ? (routes!.first['duration'] as num?)?.toDouble() ?? 0
            : 0;
        if (seconds > 0) return (seconds / 60).round();
      }
    } catch (_) {
      // Fall back to a local estimate when routing is temporarily offline.
    }
    final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
    return (distanceKm / 55 * 60).round().clamp(1, 24 * 60);
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return AppLocalizations.translate('$minutes дақиқа');
    if (minutes == 0) return AppLocalizations.translate('$hours соат');
    return AppLocalizations.translate('$hours соат $minutes дақиқа');
  }

  Future<void> _handleCreateOrder() async {
    if (_selectedFromLocation == null || _selectedToLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Лутфан макони оғоз ва таъинро интихоб кунед',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _publishAnimationController.repeat();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_route_from', _selectedFromLocation!);
      await prefs.setString('active_route_to', _selectedToLocation!);

      final now = DateTime.now();
      if (_departureTime == null) {
        throw const FormatException('Invalid departure time');
      }
      final durationTotalMinutes = await _calculateDurationMinutes();
      if (durationTotalMinutes <= 0) {
        throw const FormatException('Route duration is unavailable');
      }

      // Publish to the server FIRST and capture the REAL server id (UUID).
      // Storing that id locally is what lets the delete button remove the
      // SAME announcement from the server afterwards (and from passengers).
      final serverTrip = await ApiService.createTrip({
        'driver_id': _driverPhone,
        'driver_name': _driverName,
        'driver_phone': _driverPhone,
        'from_location': _selectedFromLocation!,
        'to_location': _selectedToLocation!,
        'departure_time': _departureTime!.toIso8601String(),
        'duration_minutes': durationTotalMinutes,
        'car_brand': prefs.getString('driver_car_brand') ?? '',
        'car_model': prefs.getString('driver_car_model') ?? '',
        'car_color': prefs.getString('driver_car_color') ?? '',
        'car_plate': prefs.getString('driver_plate_number') ?? '',
        'price':
            int.tryParse(
              _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'available_seats': _seats,
      });

      // Save the announcement so it appears on the driver home screen AND in
      // the passenger route search (real data вЂ” no mock). Car info comes from
      // the driver registration data stored earlier.
      final order = Order(
        id:
            serverTrip?['id']?.toString() ??
            now.millisecondsSinceEpoch.toString(),
        fromLocation: _selectedFromLocation!,
        toLocation: _selectedToLocation!,
        price: _priceController.text.trim(),
        duration: _formatDuration(durationTotalMinutes),
        durationMinutes: durationTotalMinutes,
        seats: _seats,
        notes: '',
        createdAt: now.toIso8601String(),
        departureTime: _departureTime!.toIso8601String(),
        driverName: _driverName,
        driverPhone: _driverPhone,
        carBrand: prefs.getString('driver_car_brand') ?? '',
        carModel: prefs.getString('driver_car_model') ?? '',
        carColor: prefs.getString('driver_car_color') ?? '',
        carPlate: prefs.getString('driver_plate_number') ?? '',
      );

      // Plain async I/O (SharedPreferences) вЂ” never blocks the UI thread.
      // Keeps the announcement on THIS device (driver home screen list).
      await saveOrder(order);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Хатогӣ — эълон нигоҳ дошта нашуд',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _publishAnimationController.stop();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Эълон кардан')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: LightGlassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From Location Selection
                GestureDetector(
                  onTap: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSelectionScreen(
                          title: AppLocalizations.translate(
                            'Аз куҷо меравед?',
                          ),
                          locations: _allLocations,
                          selectedLocation: _selectedFromLocation,
                        ),
                      ),
                    );
                    if (selected != null) {
                      setState(() => _selectedFromLocation = selected);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E7F1)),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A173B73),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.trip_origin,
                          size: 24,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedFromLocation ??
                                'Аз куҷо меравед?',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedFromLocation != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(
                          AppIcons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // To Location Selection
                GestureDetector(
                  onTap: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSelectionScreen(
                          title: AppLocalizations.translate(
                            'Ба куҷо рафтан мехоҳед?',
                          ),
                          locations: _allLocations,
                          selectedLocation: _selectedToLocation,
                        ),
                      ),
                    );
                    if (selected != null) {
                      setState(() => _selectedToLocation = selected);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E7F1)),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A173B73),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.location_on, size: 24, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedToLocation ??
                                'Ба куҷо рафтан мехоҳед?',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedToLocation != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(
                          AppIcons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Price input
                TextFormField(
                  controller: _priceController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.translate(
                        'Нархро ворид кунед',
                      );
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.translate(
                      'Нарх (сомонӣ)',
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFE0E7F1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFE0E7F1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(
                        color: Color(0xFF0066FF),
                        width: 1.5,
                      ),
                    ),
                    hintText: AppLocalizations.translate('Масалан: 150'),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _selectDepartureTime,
                  icon: const Icon(AppIcons.event_rounded),
                  label: Text(
                    _departureTime == null
                        ? 'Рӯз ва вақти рафтанро интихоб кунед'
                        : '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')} '
                              '${_departureTime!.day.toString().padLeft(2, '0')}.${_departureTime!.month.toString().padLeft(2, '0')}.${_departureTime!.year}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF31548C),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF31548C)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Seats selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate(
                        'Ҷойҳои холӣ: $_seats',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSeatButton(
                          icon: AppIcons.remove_rounded,
                          onTap: _seats > 1
                              ? () => setState(() => _seats--)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Seats display
                        Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF3385FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x330066FF),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Text(
                                '$_seats',
                                key: ValueKey(_seats),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSeatButton(
                          icon: AppIcons.add_rounded,
                          onTap: _seats < 8
                              ? () => setState(() => _seats++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Create order button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1769E0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF9CC2FF),
                      elevation: 8,
                      shadowColor: const Color(0x660066FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _publishAnimationController,
                          builder: (context, child) => Transform.rotate(
                            angle: _isLoading
                                ? _publishAnimationController.value * 6.28318
                                : 0,
                            child: child,
                          ),
                          child: const Icon(AppIcons.directions_car_rounded),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.translate('Эълон кардан'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x22173B73),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: onTap == null ? Colors.grey[300] : const Color(0xFF0066FF),
          ),
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String price;
  final String duration;
  final int seats;
  final String passengerPhone;
  final String passengerName;

  const OrderDetailsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.duration,
    required this.seats,
    required this.passengerPhone,
    this.passengerName = 'РњСѓСЃРѕС„РёСЂ',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.translate('Тафсилоти заказ'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.map_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.translate('Харита'),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Route information
            Row(
              children: [
                // From location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.translate('Аз'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromLocation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  AppIcons.arrow_forward_rounded,
                  size: 24,
                  color: Colors.grey[400],
                ),
                // To location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.translate('Ба'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toLocation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Divider
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 24),
            // Price
            _buildInfoRow(
              icon: AppIcons.attach_money_rounded,
              label: AppLocalizations.translate('Нарх'),
              value: price,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 16),
            // Duration
            _buildInfoRow(
              icon: AppIcons.access_time_rounded,
              label: AppLocalizations.translate('Вақт'),
              value: duration,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 16),
            // Seats
            _buildInfoRow(
              icon: AppIcons.airline_seat_recline_normal_rounded,
              label: AppLocalizations.translate('Ҷойҳои холӣ'),
              value: '$seats ҷой',
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 24),
            // Divider
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 24),
            // Passenger info
            Text(
              AppLocalizations.translate('Маълумоти мусофир'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.person_rounded,
                        size: 24,
                        color: const Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.translate('РќРѕРј:'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      passengerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        AppIcons.phone_rounded,
                        size: 24,
                        color: const Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.translate('Телефон:'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      passengerPhone,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.translate(
                          'Заказ қабул шуд!',
                        ),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate back to driver home after delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const DriverHomeScreen(
                            driverName: 'Ронанда',
                            driverPhone: '',
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  AppLocalizations.translate(
                    'Заказро қабул кардан',
                  ),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order model вЂ” represents a driver's ride announcement (СЌСЉР»РѕРЅ)
class Order {
  final String id;
  final String fromLocation;
  final String toLocation;
  final String price;
  final String duration;
  final int durationMinutes;
  final int seats;
  final String notes;
  final String createdAt;
  final String departureTime;
  final String driverName;
  final String driverPhone;
  final String carBrand;
  final String carModel;
  final String carColor;
  final String carPlate;

  Order({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.duration,
    this.durationMinutes = 0,
    required this.seats,
    required this.notes,
    required this.createdAt,
    this.departureTime = '',
    this.driverName = '',
    this.driverPhone = '',
    this.carBrand = '',
    this.carModel = '',
    this.carColor = '',
    this.carPlate = '',
  });

  Order copyWith({int? seats}) => Order(
    id: id,
    fromLocation: fromLocation,
    toLocation: toLocation,
    price: price,
    duration: duration,
    durationMinutes: durationMinutes,
    seats: seats ?? this.seats,
    notes: notes,
    createdAt: createdAt,
    departureTime: departureTime,
    driverName: driverName,
    driverPhone: driverPhone,
    carBrand: carBrand,
    carModel: carModel,
    carColor: carColor,
    carPlate: carPlate,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromLocation': fromLocation,
    'toLocation': toLocation,
    'price': price,
    'duration': duration,
    'durationMinutes': durationMinutes,
    'seats': seats,
    'notes': notes,
    'createdAt': createdAt,
    'departureTime': departureTime,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'carBrand': carBrand,
    'carModel': carModel,
    'carColor': carColor,
    'carPlate': carPlate,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String? ?? '',
    fromLocation: json['fromLocation'] as String? ?? '',
    toLocation: json['toLocation'] as String? ?? '',
    price: json['price'] as String? ?? '',
    duration: json['duration'] as String? ?? '',
    durationMinutes: json['durationMinutes'] as int? ?? 0,
    seats: json['seats'] as int? ?? 0,
    notes: json['notes'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    departureTime: json['departureTime'] as String? ?? '',
    driverName: json['driverName'] as String? ?? '',
    driverPhone: json['driverPhone'] as String? ?? '',
    carBrand: json['carBrand'] as String? ?? '',
    carModel: json['carModel'] as String? ?? '',
    carColor: json['carColor'] as String? ?? '',
    carPlate: json['carPlate'] as String? ?? '',
  );
}

/// Persists an order to SharedPreferences so it survives app restarts / refresh
Future<void> saveOrder(Order order) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  orders.add(order);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((o) => o.toJson()).toList()),
  );
}

Future<void> updateOrderSeats(String orderId, int seats) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  final index = orders.indexWhere((order) => order.id == orderId);
  if (index < 0) return;
  orders[index] = orders[index].copyWith(seats: seats);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((order) => order.toJson()).toList()),
  );
}

/// Loads all saved orders from SharedPreferences
Future<List<Order>> loadOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final ordersJson = prefs.getString('saved_orders');
  if (ordersJson == null || ordersJson.isEmpty) return [];
  final List<dynamic> decoded = jsonDecode(ordersJson);
  return decoded
      .map((item) => Order.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Deletes a single order by id вЂ” from the SERVER (which also broadcasts
/// `trip_deleted` to every passenger device, so the announcement disappears
/// from the РјСѓСЃРѕС„РёСЂ app too) AND from local storage.
Future<void> deleteOrder(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  Order? order;
  for (final o in orders) {
    if (o.id == id) {
      order = o;
      break;
    }
  }

  // 1) Delete on the server. New announcements store the server UUID as
  //    their local id, so a direct call works. Older saved announcements
  //    have a local timestamp id, so we fall back to matching the server
  //    trip by its route/driver/price and delete that exact row.
  final serverId = _looksLikeUuid(id) ? id : await _resolveServerTripId(order);
  if (serverId != null && serverId.isNotEmpty) {
    // deleteTrip returns true when the server confirmed the delete OR the
    // trip was already gone (404). It returns false only when unreachable вЂ”
    // in that case we still remove the local copy so the app keeps working.
    await ApiService.deleteTrip(serverId);
  }

  // 2) Always remove the local copy.
  orders.removeWhere((o) => o.id == id);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((o) => o.toJson()).toList()),
  );
}

bool _looksLikeUuid(String id) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(id);

/// Finds the server trip matching the given local order by its content
/// (route + driver + price) so old announcements that only carry a local
/// timestamp id can still be removed from the server.
Future<String?> _resolveServerTripId(Order? order) async {
  if (order == null) return null;
  final trips = await ApiService.fetchTrips();
  final norm = (String? s) => (s ?? '').trim().toLowerCase();
  final priceNum = int.tryParse(order.price.replaceAll(RegExp(r'[^0-9]'), ''));
  final candidates = <Map<String, dynamic>>[];
  for (final t in trips) {
    if (norm(t['from_location']) != norm(order.fromLocation)) continue;
    if (norm(t['to_location']) != norm(order.toLocation)) continue;
    if (order.driverPhone.isNotEmpty &&
        norm(t['driver_phone']) != norm(order.driverPhone) &&
        norm(t['driver_id']) != norm(order.driverPhone)) {
      continue;
    }
    if (priceNum != null &&
        t['price'] is num &&
        (t['price'] as num) != priceNum) {
      continue;
    }
    candidates.add(t);
  }
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.first['id']?.toString();
  final depart = order.departureTime.trim();
  if (depart.isNotEmpty) {
    for (final t in candidates) {
      if (norm(t['departure_time']) == norm(depart)) {
        return t['id']?.toString();
      }
    }
  }
  return candidates.first['id']?.toString();
}

class DriverHomeScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const DriverHomeScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImage;
  int _currentIndex = 0;
  bool _isOnline = true;
  List<Order> _orders = [];
  String? _activeTripId;
  final Set<String> _completedTripIds = <String>{};
  final Set<String> _dismissingTripIds = <String>{};
  final List<Map<String, dynamic>> _passengerMessages = [];
  StreamSubscription<Map<String, dynamic>>? _passengerBookedSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripUpdatedSubscription;
  StreamSubscription<Map<String, dynamic>>? _reviewCreatedSubscription;
  double _driverRating = 0;
  Timer? _bookingRefreshTimer;
  Timer? _tripCompletionTimer;
  int? _tripEndCountdown;
  bool _isEndingTripFromHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
    _loadActiveTripId();
    _connectDriverMessages();
  }

  Future<void> _loadActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _activeTripId = prefs.getString('active_trip_id'));
  }

  Future<void> _handleTripEnded(String tripId) async {
    if (!mounted || _completedTripIds.contains(tripId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trip_started', false);
    await prefs.remove('active_trip_id');
    if (!mounted) return;
    setState(() {
      _activeTripId = null;
      _currentIndex = 0;
      _completedTripIds.add(tripId);
      _tripEndCountdown = 3;
    });

    _tripCompletionTimer?.cancel();
    _tripCompletionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_completedTripIds.contains(tripId)) {
        timer.cancel();
        return;
      }
      final countdown = _tripEndCountdown ?? 0;
      if (countdown > 1) {
        setState(() => _tripEndCountdown = countdown - 1);
        return;
      }
      timer.cancel();
      setState(() {
        _tripEndCountdown = null;
        _dismissingTripIds.add(tripId);
      });
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (!mounted) return;
        setState(() {
          _orders.removeWhere((order) => order.id == tripId);
          _completedTripIds.remove(tripId);
          _dismissingTripIds.remove(tripId);
        });
      });
    });
  }

  Future<void> _endActiveTripFromHome() async {
    if (_isEndingTripFromHome || _activeTripId == null) return;
    final tripId = _activeTripId!;
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('user_phone');
    if (driverId == null || driverId.isEmpty) {
      await _handleTripEnded(tripId);
      return;
    }

    setState(() => _isEndingTripFromHome = true);
    final result = await SocketService.instance.endTrip(
      tripId: tripId,
      driverId: driverId,
    );
    if (!mounted) return;
    setState(() => _isEndingTripFromHome = false);
    final completedLocally =
        result['ok'] == true ||
        result['error']?.toString() == 'Not connected to the server';
    if (completedLocally) {
      await _handleTripEnded(tripId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ??
                AppLocalizations.translate('Хато рӯй дод'),
          ),
        ),
      );
    }
  }

  Future<void> _connectDriverMessages() async {
    _passengerBookedSubscription = SocketService.instance.onPassengerBooked
        .listen((message) {
          if (!_sameDriver(message['driver_id'])) return;
          if (!mounted) return;
          _mergeDriverBookings([message]);
        });
    _tripUpdatedSubscription = SocketService.instance.onTripUpdated.listen(
      (trip) => _applyUpdatedTripSeats(trip),
    );
    _reviewCreatedSubscription = SocketService.instance.onReviewCreated.listen((
      review,
    ) {
      if (!_sameDriver(review['driver_id']) || !mounted) return;
      final rating = double.tryParse(review['rating']?.toString() ?? '');
      if (rating != null) setState(() => _driverRating = rating);
    });
    await _refreshDriverBookings();
    await SocketService.instance.connect(
      userId: widget.driverPhone,
      role: 'driver',
    );
    await _refreshDriverBookings();
    _bookingRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshDriverBookings();
    });
  }

  bool _sameDriver(Object? value) {
    String digits(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');
    final received = digits(value?.toString() ?? '');
    final current = digits(widget.driverPhone);
    return received.isNotEmpty && current.isNotEmpty && received == current;
  }

  Future<void> _refreshDriverBookings() async {
    final bookings = await ApiService.fetchDriverBookings(widget.driverPhone);
    _mergeDriverBookings(bookings);
  }

  void _mergeDriverBookings(List<Map<String, dynamic>> bookings) {
    if (!mounted || bookings.isEmpty) return;
    setState(() {
      for (final message in bookings.reversed) {
        final messageId = message['id']?.toString();
        if (messageId == null ||
            !_passengerMessages.any(
              (existing) => existing['id']?.toString() == messageId,
            )) {
          _passengerMessages.add(message);
        }
      }
    });
  }

  Future<void> _applyUpdatedTripSeats(Map<String, dynamic> trip) async {
    final tripId = trip['id']?.toString();
    final seats = int.tryParse(trip['available_seats']?.toString() ?? '');
    if (tripId == null || seats == null) return;
    await updateOrderSeats(tripId, seats);
    if (!mounted) return;
    setState(() {
      final index = _orders.indexWhere((order) => order.id == tripId);
      if (index >= 0) _orders[index] = _orders[index].copyWith(seats: seats);
    });
  }

  Future<void> _loadOrders() async {
    final orders = await loadOrders();
    if (!mounted) return;
    setState(() => _orders = orders.reversed.toList());
  }

  Future<void> _deleteOrderWithAnimation(String orderId) async {
    if (_dismissingTripIds.contains(orderId)) return;
    setState(() => _dismissingTripIds.add(orderId));
    await Future<void>.delayed(const Duration(milliseconds: 360));
    await deleteOrder(orderId);
    if (!mounted) return;
    final orders = await loadOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders.reversed.toList();
      _dismissingTripIds.remove(orderId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passengerBookedSubscription?.cancel();
    _tripUpdatedSubscription?.cancel();
    _reviewCreatedSubscription?.cancel();
    _bookingRefreshTimer?.cancel();
    _tripCompletionTimer?.cancel();
    SocketService.instance.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOnline = state == AppLifecycleState.resumed;
    if (mounted && _isOnline != isOnline) {
      setState(() => _isOnline = isOnline);
    }
    if (state == AppLifecycleState.resumed) {
      _refreshDriverBookings();
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImage = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _resetProfileAndRestart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      (route) => false,
    );
  }

  void _openSettingsScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  Widget _buildTripEndCountdown() {
    final countdown = _tripEndCountdown;
    if (countdown == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB9D2FF)),
        ),
        child: Column(
          children: [
            Text(
              AppLocalizations.translate(
                'Сафар ба анҷом расид',
              ),
              style: TextStyle(
                color: Color(0xFF1456B8),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                '$countdown',
                key: ValueKey(countdown),
                style: const TextStyle(
                  color: Color(0xFF0066FF),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedTabStack(
                  index: _currentIndex,
                  children: [
                    _buildHomeTab(),
                    _buildRouteTab(),
                    _buildMessagesTab(),
                    _buildProfileTab(),
                  ],
                ),
              ),
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate('Салом, Ронанда!'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.translate(
                        'Барои кор омодаед?',
                      ),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openSettingsScreen,
                tooltip: AppLocalizations.translate('Танзимот'),
                icon: Icon(
                  AppIcons.settings_rounded,
                  size: 28,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTripEndCountdown(),

          // "Закази нав" button вЂ” compact card
          GestureDetector(
            onTap: () async {
              final wasCreated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateOrderScreen(
                    driverName: widget.driverName,
                    driverPhone: widget.driverPhone,
                  ),
                ),
              );
              if (wasCreated == true && mounted) {
                _loadOrders();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF3399FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.directions_car_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('Эълон кардан'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.translate(
                            'Барои эълон кардан зер кунед',
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section title: Р­СЉР»РѕРЅТіРѕ
          Row(
            children: [
              const Icon(
                AppIcons.campaign_rounded,
                size: 20,
                color: Color(0xFF0066FF),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.translate('Эълонҳои ман'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_orders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_orders.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Orders list
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.inbox_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.translate(
                            'Ҳанӯз эълон вуҷуд надорад',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.translate(
                            'Аввалин эълони худро созед',
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isCompleted = _completedTripIds.contains(order.id);
    final isDismissing = _dismissingTripIds.contains(order.id);
    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        opacity: isDismissing ? 0 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route row: from в†’ to
              Row(
                children: [
                  // Route icons
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 28, color: Colors.grey[300]),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Locations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.fromLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          order.toLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          AppIcons.attach_money_rounded,
                          size: 18,
                          color: Color(0xFF0066FF),
                        ),
                        Text(
                          AppLocalizations.translate('${order.price} СЃРѕРј'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Bottom info row
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildOrderInfoChip(
                          icon: AppIcons.access_time_rounded,
                          label: order.duration.isNotEmpty
                              ? '${order.duration} дақ'
                              : 'вЂ”',
                          color: Colors.blue,
                        ),
                        _buildOrderInfoChip(
                          icon: AppIcons.airline_seat_recline_normal_rounded,
                          label: AppLocalizations.translate(
                            '${order.seats} ҷой',
                          ),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: () => _deleteOrderWithAnimation(order.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        AppIcons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isCompleted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.translate(
                      'Масир ба анҷом расид',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF168A52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else ...[
                // Start trip button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_activeTripId == order.id) {
                        _endActiveTripFromHome();
                      } else {
                        _startTrip(order);
                      }
                    },
                    icon: Icon(
                      _activeTripId == order.id
                          ? AppIcons.stop_circle_outlined
                          : AppIcons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.translate(
                        _activeTripId == order.id
                            ? 'Анҷоми сафар'
                            : 'Оғози сафар',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTrip(Order order) async {
    final fromCity = order.fromLocation;
    final toCity = order.toLocation;
    final prefs = await SharedPreferences.getInstance();
    // The map (OSRM) is the source of truth: whatever the route screen shows,
    // the assistant reads out loud. Fallbacks only kick in if OSRM never ran.
    final osrmDurationSeconds =
        prefs.getInt('route_osrm_duration_seconds') ?? 0;
    final osrmDistanceKm = prefs.getDouble('route_osrm_distance_km') ?? 0;
    final distanceKm = osrmDistanceKm > 0
        ? osrmDistanceKm
        : _estimateDistanceKm(fromCity, toCity);
    final durationMinutes = osrmDurationSeconds > 0
        ? (osrmDurationSeconds / 60).round()
        : order.durationMinutes > 0
        ? order.durationMinutes
        : (distanceKm > 0 ? (distanceKm / 55 * 60).round() : 0);
    unawaited(
      TTSService.instance.announcePassengerTrip(
        startCity: fromCity,
        finishCity: toCity,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      ),
    );

    await prefs.setString('active_route_from', order.fromLocation);
    await prefs.setString('active_route_to', order.toLocation);
    await prefs.setString('active_trip_id', order.id);
    await prefs.setString('user_phone', widget.driverPhone);
    await prefs.setBool('trip_started', true);
    await prefs.setInt('active_route_duration_minutes', durationMinutes);
    await prefs.setDouble('active_route_distance_km', distanceKm);
    // Ask the route map to frame A+B first, then zoom in on A once the
    // assistant starts speaking.
    await prefs.setBool('route_fit_pending', true);
    if (!mounted) return;
    setState(() {
      _activeTripId = order.id;
      _currentIndex = 1;
    });
  }

  /// Estimates the straight-line distance (km) between two known cities.
  double _estimateDistanceKm(String fromCity, String toCity) {
    final from = taxiLocationCoordinates[fromCity];
    final to = taxiLocationCoordinates[toCity];
    if (from == null || to == null) return 0;
    return const Distance().as(LengthUnit.Kilometer, from, to);
  }

  Widget _buildOrderInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTab() {
    return _RouteMapTab(onTripEnded: (tripId) => _handleTripEnded(tripId));
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildRouteTab();
      case 2:
        return _buildMessagesTab();
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildMessagesTab() {
    if (_passengerMessages.isNotEmpty) {
      return Column(
        children: [
          _buildMessageHeader(
            title: AppLocalizations.translate('Паёмҳо'),
            onClear: _clearDriverMessages,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _passengerMessages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = _passengerMessages[index];
                final name = message['passenger_name']?.toString().trim();
                final passengerName = name == null || name.isEmpty
                    ? 'РњСѓСЃРѕС„РёСЂ'
                    : name;
                final requestedSeats =
                    int.tryParse(
                      message['requested_seats']?.toString() ?? '',
                    ) ??
                    1;
                final status = message['status']?.toString() ?? 'pending';
                final statusColor = status == 'approved'
                    ? const Color(0xFF159957)
                    : status == 'rejected'
                    ? const Color(0xFFD64545)
                    : const Color(0xFF1769E0);
                final statusText = status == 'approved'
                    ? 'Иҷозат дода шуд'
                    : status == 'rejected'
                    ? 'Рад карда шуд'
                    : 'Интизорӣ';
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final updated = await Navigator.of(context)
                        .push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (_) => BookingDecisionScreen(
                              booking: message,
                              driverId: widget.driverPhone,
                            ),
                          ),
                        );
                    if (!mounted || updated == null) return;
                    setState(() {
                      final messageId = updated['id']?.toString();
                      final messageIndex = _passengerMessages.indexWhere(
                        (item) => item['id']?.toString() == messageId,
                      );
                      if (messageIndex >= 0)
                        _passengerMessages[messageIndex] = updated;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(
                            AppIcons.person_rounded,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.translate(
                                  '$passengerName ҷойи сафарро брон кард',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppLocalizations.translate(
                                  '$requestedSeats ҷой мехоҳад',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          AppIcons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.message_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.translate('Паёмҳо'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageHeader({
    required String title,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            tooltip: AppLocalizations.translate(
              'Ҳамаашро тоза кардан',
            ),
            icon: const Icon(
              AppIcons.delete_sweep_rounded,
              color: Color(0xFFD64545),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDriverMessages() async {
    final deleted = await ApiService.deleteAllBookings(
      driverId: widget.driverPhone,
    );
    if (!mounted || !deleted) return;
    setState(() => _passengerMessages.clear());
  }

  String _cleanDebugText(String value) {
    if (value.contains('TextEditingController') ||
        value.contains('TextEditingValue')) {
      var match = RegExp(r'text:\s*-\|\s*([^|]+?)\s*\|').firstMatch(value);
      if (match != null) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty && !extracted.contains('selection')) {
          return extracted;
        }
      }

      match = RegExp(r"'([^']+)'").firstMatch(value);
      if (match != null) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty &&
            !extracted.contains('TextEditing') &&
            !extracted.contains('selection') &&
            extracted.length < 50) {
          return extracted;
        }
      }
    }
    return value;
  }

  Future<Map<String, String>> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    var firstName = prefs.getString('user_first_name') ?? '';
    var lastName = prefs.getString('user_last_name') ?? '';
    final phone = prefs.getString('user_phone') ?? widget.driverPhone;
    final birthYear = prefs.getString('user_birth_year') ?? '';
    final gender = prefs.getString('user_gender') ?? 'вЂ”';
    final carBrand = prefs.getString('driver_car_brand') ?? 'вЂ”';
    final carColor = prefs.getString('driver_car_color') ?? 'вЂ”';
    final carModel = prefs.getString('driver_car_model') ?? 'вЂ”';
    final plateNumber = prefs.getString('driver_plate_number') ?? 'вЂ”';

    firstName = _cleanDebugText(firstName);
    lastName = _cleanDebugText(lastName);

    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? [firstName, lastName].where((item) => item.isNotEmpty).join(' ')
        : (prefs.getString('user_name') ?? 'вЂ”');

    return {
      'full_name': fullName,
      'phone': phone,
      'role': 'Ронанда',
      'birth_year': birthYear,
      'gender': gender,
      'car_brand': carBrand,
      'car_color': carColor,
      'car_model': carModel,
      'plate_number': plateNumber,
    };
  }

  Future<void> _showProfileEditor() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneController = TextEditingController(
      text: prefs.getString('user_phone') ?? widget.driverPhone,
    );
    final carModelController = TextEditingController(
      text: prefs.getString('driver_car_model') ?? '',
    );
    final plateController = TextEditingController(
      text: prefs.getString('driver_plate_number') ?? '',
    );
    String selectedBrand = prefs.getString('driver_car_brand') ?? '';
    String selectedColor = prefs.getString('driver_car_color') ?? '';

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.translate(
                  'Редактировать профиль',
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.translate(
                          'Рақами телефон',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarBrandSelectionScreen(
                              brands: supportedCarBrands,
                              selectedBrand: selectedBrand.isNotEmpty
                                  ? selectedBrand
                                  : null,
                            ),
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedBrand = result);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.directions_car,
                              color: Color(0xFF0066FF),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedBrand.isNotEmpty
                                    ? selectedBrand
                                    : 'Маркаи мошин',
                                style: TextStyle(
                                  color: selectedBrand.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(AppIcons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: carModelController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.translate(
                          'Модели мошин',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarColorSelectionScreen(
                              colors: const [
                                'Сабз',
                                'Сафед',
                                'РЎРёС‘Ті',
                                'РЎСѓСЂС…',
                                'Кабуд',
                                'Зард',
                                'Нилӯфар',
                                'Беж',
                                'Кул',
                                'Тилоӣ',
                              ],
                              selectedColor: selectedColor.isNotEmpty
                                  ? selectedColor
                                  : null,
                            ),
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedColor = result);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: selectedColor.isNotEmpty
                                    ? {
                                            'Сабз': Colors.green,
                                            'Сафед': Colors.white,
                                            'РЎРёС‘Ті': Colors.black,
                                            'РЎСѓСЂС…': Colors.red,
                                            'Кабуд': Colors.blue,
                                            'Зард': Colors.yellow,
                                            'Нилӯфар': Colors.purple,
                                            'Беж': Colors.brown,
                                            'Кул': Colors.grey,
                                            'Тилоӣ': Colors.amber,
                                          }[selectedColor] ??
                                          Colors.grey
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                selectedColor.isNotEmpty
                                    ? selectedColor
                                    : 'Ранги мошин',
                                style: TextStyle(
                                  color: selectedColor.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(AppIcons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: plateController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.translate(
                          'Рақами давлатӣ',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.translate('Бекор')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final phoneValue = phoneController.text.trim();
                    final brandValue = selectedBrand.trim();
                    final modelValue = carModelController.text.trim();
                    final colorValue = selectedColor.trim();
                    final plateValue = plateController.text.trim();

                    if (phoneValue.isNotEmpty) {
                      await prefs.setString('user_phone', phoneValue);
                    }
                    if (brandValue.isNotEmpty) {
                      await prefs.setString('driver_car_brand', brandValue);
                    }
                    if (modelValue.isNotEmpty) {
                      await prefs.setString('driver_car_model', modelValue);
                    }
                    if (colorValue.isNotEmpty) {
                      await prefs.setString('driver_car_color', colorValue);
                    }
                    if (plateValue.isNotEmpty) {
                      await prefs.setString('driver_plate_number', plateValue);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(AppLocalizations.translate('Сохранить')),
                ),
              ],
            );
          },
        );
      },
    );

    if (changed == true) {
      setState(() {});
    }
  }

  /* Widget _buildProfileTab() {
    return FutureBuilder<Map<String, String>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'full_name': widget.driverName,
              'phone': widget.driverPhone,
              'role': 'Ронанда',
              'birth_year': 'вЂ”',
              'gender': 'вЂ”',
              'car_brand': 'вЂ”',
              'car_color': 'вЂ”',
              'car_model': 'вЂ”',
              'plate_number': 'вЂ”',
            };

        final vehicleStats = [
          _DriverStat(
            icon: AppIcons.directions_car_filled_rounded,
            label: AppLocalizations.translate('Модел'),
            value: data['car_model'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.confirmation_number_rounded,
            label: AppLocalizations.translate('Рақами давлатӣ'),
            value: data['plate_number'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.palette_rounded,
            label: AppLocalizations.translate('Ранги мошин'),
            value: data['car_color'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.calendar_month_rounded,
            label: AppLocalizations.translate('Соли таваллуд'),
            value: data['birth_year'] ?? 'вЂ”',
          ),
        ];

        return Container(
          color: const Color(0xFFF8F9FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331565C0),
                          blurRadius: 20,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isOnline
                                      ? const Color(0xFF22C55E)
                                      : Colors.grey,
                                  width: 3,
                                ),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: MemoryImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(
                                      AppIcons.person_rounded,
                                      size: 36,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  AppIcons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 42),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                              Text(
                                data['full_name'] ?? 'Ронанда',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Text(AppLocalizations.translate('Ронанда'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            AppIcons.phone_rounded,
                                            size: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.82,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              data['phone'] ?? 'вЂ”',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withValues(
                                                  alpha: 0.82,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: _openSettingsScreen,
                                tooltip: AppLocalizations.translate('Танзимот'),
                                icon: const Icon(
                                  AppIcons.settings_rounded,
                                  size: 23,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: double.infinity,
                  child: _ProfileRatingCard(),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: vehicleStats
                      .map((stat) => _buildDriverStatBadge(stat))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showProfileEditor,
                    icon: const Icon(AppIcons.edit_rounded, size: 18),
                    label: Text(AppLocalizations.translate('Таҳрир кардан')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0066FF),
                      side: const BorderSide(color: Color(0xFF0066FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  */

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, String>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'full_name': widget.driverName,
              'phone': widget.driverPhone,
              'birth_year': 'вЂ”',
              'car_color': 'вЂ”',
              'car_model': 'вЂ”',
              'plate_number': 'вЂ”',
            };
        final vehicleStats = [
          _DriverStat(
            icon: AppIcons.directions_car_filled_rounded,
            label: AppLocalizations.translate('Модел'),
            value: data['car_model'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.confirmation_number_rounded,
            label: AppLocalizations.translate('Рақами давлатӣ'),
            value: data['plate_number'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.palette_rounded,
            label: AppLocalizations.translate('Ранги мошин'),
            value: data['car_color'] ?? 'вЂ”',
          ),
          _DriverStat(
            icon: AppIcons.calendar_month_rounded,
            label: AppLocalizations.translate('Соли таваллуд'),
            value: data['birth_year'] ?? 'вЂ”',
          ),
        ];

        return Container(
          color: const Color(0xFFF8F9FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331565C0),
                        blurRadius: 20,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isOnline
                                          ? const Color(0xFF22C55E)
                                          : Colors.grey,
                                      width: 3,
                                    ),
                                    image: _profileImage == null
                                        ? null
                                        : DecorationImage(
                                            image: MemoryImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: _profileImage == null
                                      ? const Icon(
                                          AppIcons.person_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      AppIcons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 42),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['full_name'] ?? 'Ронанда',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      AppLocalizations.translate(
                                        'Ронанда',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        AppIcons.phone_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          data['phone'] ?? 'вЂ”',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _openSettingsScreen,
                            tooltip: AppLocalizations.translate(
                              'Танзимот',
                            ),
                            icon: const Icon(
                              AppIcons.settings_rounded,
                              size: 23,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 0,
                        child: _ProfileRatingBadge(rating: _driverRating),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicleStats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 116,
                  ),
                  itemBuilder: (context, index) =>
                      _buildDriverStatBadge(vehicleStats[index]),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showProfileEditor,
                    icon: const Icon(AppIcons.edit_rounded, size: 18),
                    label: Text(
                      AppLocalizations.translate('Таҳрир кардан'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173B73),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileActionTile(
            icon: AppIcons.payments_rounded,
            label: AppLocalizations.translate('Даромад'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    DriverEarningsScreen(driverId: widget.driverPhone),
              ),
            ),
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.history_rounded,
            label: AppLocalizations.translate('Таърихи сафарҳо'),
            onTap: _showRideHistory,
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.info_rounded,
            label: AppLocalizations.translate(
              'Дар бораи барнома',
            ),
            onTap: _showAboutApp,
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.settings_rounded,
            label: AppLocalizations.translate('Танзимот'),
            onTap: _openSettingsScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Color(0xFFF0F2F5),
    );
  }

  Widget _buildProfileActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF0066FF), size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                AppIcons.chevron_right_rounded,
                color: Color(0xFF9AA5B5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAboutApp() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DriverAboutSheet(),
    );
  }

  Future<void> _showRideHistory() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DriverRideHistorySheet(),
    );
  }

  Widget _buildDriverStatBadge(_DriverStat stat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173B73),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: const Color(0xFF0066FF), size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 3),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedBottomNavigation(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedColor: Colors.white,
      unselectedColor: Colors.white70,
      items: [
        AnimatedNavigationItem(
          icon: AppIcons.home_rounded,
          label: '\u0410\u0441\u043e\u0441\u04e3',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.route_rounded,
          label: '\u041c\u0430\u0441\u0438\u0440',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.orders,
          label: '\u0424\u0430\u0440\u043c\u043e\u0438\u0448\u04b3\u043e',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.person_rounded,
          label: '\u041f\u0440\u043e\u0444\u0438\u043b',
        ),
      ],
    );
  }
}

class BookingDecisionScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String driverId;

  const BookingDecisionScreen({
    super.key,
    required this.booking,
    required this.driverId,
  });

  @override
  State<BookingDecisionScreen> createState() => _BookingDecisionScreenState();
}

class _BookingDecisionScreenState extends State<BookingDecisionScreen> {
  bool _sending = false;

  Future<void> _decide(bool approved) async {
    if (_sending) return;
    setState(() => _sending = true);
    final result = await ApiService.decideBooking(
      bookingId: widget.booking['id']?.toString() ?? '',
      driverId: widget.driverId,
      approved: approved,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result['ok'] == true) {
      final booking = result['booking'];
      Navigator.of(
        context,
      ).pop(booking is Map<String, dynamic> ? booking : widget.booking);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['error']?.toString() ??
              AppLocalizations.translate('Хатогӣ рӯй дод'),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengerName = widget.booking['passenger_name']?.toString().trim();
    final from = widget.booking['from_location']?.toString() ?? '';
    final to = widget.booking['to_location']?.toString() ?? '';
    final pending = widget.booking['status']?.toString() ?? 'pending';
    final requestedSeats =
        int.tryParse(widget.booking['requested_seats']?.toString() ?? '') ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Дархости брон')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              AppIcons.person_pin_circle_rounded,
              size: 72,
              color: Color(0xFF0066FF),
            ),
            const SizedBox(height: 16),
            Text(
              passengerName == null || passengerName.isEmpty
                  ? 'РњСѓСЃРѕС„РёСЂ'
                  : passengerName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '$from в†’ $to',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.translate(
                '$requestedSeats ҷой гирифтан мехоҳад',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              pending == 'pending'
                  ? 'Мусофир ҷойро брон кардан мехоҳад.'
                  : 'Ин дархост аллакай ҷавоб гирифтааст.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: pending == 'pending' && !_sending
                  ? () => _decide(true)
                  : null,
              child: Text(
                AppLocalizations.translate('Иҷозат'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: pending == 'pending' && !_sending
                  ? () => _decide(false)
                  : null,
              child: Text(
                AppLocalizations.translate('Не'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapTab extends StatefulWidget {
  final ValueChanged<String> onTripEnded;

  const _RouteMapTab({required this.onTripEnded});

  @override
  State<_RouteMapTab> createState() => _RouteMapTabState();
}

class _RouteMapTabState extends State<_RouteMapTab> {
  static const _initialLocation = LatLng(38.5598, 68.7870);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  double _zoom = 13;
  LatLng _selectedLocation = _initialLocation;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  String? _routeStartName;
  String? _routeEndName;
  List<_PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;
  bool _tripStarted = false;
  bool _isEndingTrip = false;
  LatLng? _carPosition;
  double _traveledDistance = 0;
  double _currentSpeedKmh = 0;
  int _speedMultiplier = 1;
  bool _showSpeedDemoControls = false;
  bool _speedWarningActive = false;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _focusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveRoute();
    _checkTripStarted();
    // Live GPS only вЂ” the car icon never moves by itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLocationTracking();
    });
    // Watch for the "start trip" flag: frame A+B on the map, then zoom to A
    // once the assistant has begun speaking.
    _focusCheckTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) {
        _focusCheckTimer?.cancel();
        return;
      }
      unawaited(_checkPendingRouteFocus());
    });
  }

  Future<void> _checkTripStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool('trip_started') ?? false;
    if (started && mounted) {
      setState(() => _tripStarted = true);
    }
  }

  Future<void> _loadActiveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final fromName = prefs.getString('active_route_from');
    final toName = prefs.getString('active_route_to');
    final from = fromName == null ? null : taxiLocationCoordinates[fromName];
    final to = toName == null ? null : taxiLocationCoordinates[toName];

    if (!mounted) return;
    setState(() {
      _routeStartName = fromName;
      _routeEndName = toName;
      _routeStart = from;
      _routeEnd = to;
      _routePoints = [];
      // The map (OSRM) fills distance/duration in once its route arrives.
      _routeDistance = null;
      _routeDuration = null;
    });

    if (from != null && to != null) {
      // Fetch real road route from OSRM API
      await _fetchRoute(from, to);
    }
  }

  Future<void> _endTrip() async {
    if (_isEndingTrip) return;
    final prefs = await SharedPreferences.getInstance();
    final tripId = prefs.getString('active_trip_id');
    final driverId = prefs.getString('user_phone');
    if (tripId == null || driverId == null || driverId.isEmpty) {
      await prefs.setBool('trip_started', false);
      await prefs.remove('active_trip_id');
      _resetMapAfterTrip();
      if (mounted) setState(() => _tripStarted = false);
      return;
    }
    setState(() => _isEndingTrip = true);
    final result = await SocketService.instance.endTrip(
      tripId: tripId,
      driverId: driverId,
    );
    if (!mounted) return;
    final completedLocally =
        result['ok'] == true ||
        result['error']?.toString() == 'Not connected to the server';
    if (completedLocally) {
      await prefs.setBool('trip_started', false);
      await prefs.remove('active_trip_id');
      _resetMapAfterTrip();
      setState(() {
        _tripStarted = false;
        _isEndingTrip = false;
      });
      widget.onTripEnded(tripId);
    } else {
      setState(() => _isEndingTrip = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ??
                AppLocalizations.translate('Хато рӯй дод'),
          ),
        ),
      );
    }
  }

  void _resetMapAfterTrip() {
    if (!mounted) return;
    setState(() {
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _routeStart = null;
      _routeEnd = null;
      _routeStartName = null;
      _routeEndName = null;
      _traveledDistance = 0;
      _currentSpeedKmh = 0;
      _speedMultiplier = 1;
      _speedWarningActive = false;
    });
    final position = _carPosition;
    final target = position ?? _initialLocation;
    try {
      _mapController.move(target, 15);
    } catch (_) {
      // The map controller is not attached until FlutterMap's first frame.
    }
  }

  /// Fetches real road route points from OSRM (Open Source Routing Machine)
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Роҳ дастнорас аст');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List? ?? [];
      if (routes.isEmpty) return;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List? ?? [];

      final points = coordinates
          .map((coord) {
            final pair = coord as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          })
          .where((point) => point.latitude.isFinite && point.longitude.isFinite)
          .toList();

      if (points.length < 2) {
        throw Exception('OSRM route geometry is empty');
      }

      // Extract distance (meters) and duration (seconds) from OSRM
      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      final distanceKm = distanceMeters / 1000;
      final distanceText = distanceKm >= 100
          ? '${distanceKm.toStringAsFixed(0)} РєРј'
          : '${distanceKm.toStringAsFixed(1)} РєРј';

      final hours = (durationSeconds / 3600).floor();
      final minutes = ((durationSeconds % 3600) / 60).round();
      final durationText = hours > 0
          ? '$hours соат $minutes дақ'
          : '$minutes дақ';

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        // The map itself (OSRM) is the single source of truth for the duration
        // and distance that the screen shows. The assistant reads the same
        // numbers, so the voice always matches the map card.
        _routeDuration = durationText;
        _routeDistance = distanceText;
        _traveledDistance = 0;
      });
      // Persist the OSRM estimate so the driver's start button and TTS can
      // read back exactly what the map determined.
      unawaited(_saveOsrmEstimate(distanceKm, durationSeconds));
    } catch (_) {
      // If OSRM fails, fall back to a straight line
      if (!mounted) return;
      setState(() {
        _routePoints = [from, to];
        _traveledDistance = 0;
      });
    }
  }

  Future<void> _saveOsrmEstimate(
    double distanceKm,
    double durationSeconds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('route_osrm_distance_km', distanceKm);
    await prefs.setInt('route_osrm_duration_seconds', durationSeconds.round());
    await prefs.setInt(
      'active_route_duration_minutes',
      (durationSeconds / 60).round(),
    );
    await prefs.setDouble('active_route_distance_km', distanceKm);
  }

  Future<void> _startLocationTracking() async {
    if (_isTrackingLocation || !mounted) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !mounted) {
        return;
      }
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_onPositionUpdate);
      _isTrackingLocation = true;
    } catch (_) {
      // Location is an enhancement; the route stays usable without it.
    }
  }

  void _onPositionUpdate(Position position) {
    if (!mounted || !_tripStarted) return;
    final point = LatLng(position.latitude, position.longitude);
    final speedKmh = position.speed.isFinite && position.speed > 0
        ? position.speed * 3.6
        : 0.0;
    if (speedKmh > 110 && !_speedWarningActive) {
      _speedWarningActive = true;
      unawaited(TTSService.instance.announceSpeedWarning());
    } else if (speedKmh <= 110) {
      _speedWarningActive = false;
    }
    setState(() {
      // Only real GPS fixes move the car вЂ” no simulated animation.
      if (_carPosition != null) {
        _traveledDistance += const Distance().as(
          LengthUnit.Kilometer,
          _carPosition!,
          point,
        );
      }
      _carPosition = point;
      _currentSpeedKmh = speedKmh;
    });
  }

  Widget _buildSpeedIndicator() {
    final displayedSpeed = _currentSpeedKmh * _speedMultiplier;
    final isDemo = _speedMultiplier > 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(
              () => _showSpeedDemoControls = !_showSpeedDemoControls,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDemo
                        ? AppIcons.directions_car_rounded
                        : AppIcons.speed_rounded,
                    size: 19,
                    color: const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDemo ? 'Намоишӣ ×$_speedMultiplier' : 'GPS',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppLocalizations.translate(
                        '${displayedSpeed.round()} км/соат',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 5),
                Icon(
                  _showSpeedDemoControls
                      ? AppIcons.keyboard_arrow_up_rounded
                      : AppIcons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          if (_showSpeedDemoControls) ...[
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _speedDemoButton(
                  icon: AppIcons.remove_rounded,
                  enabled: _speedMultiplier > 1,
                  onTap: () => setState(() => _speedMultiplier--),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Г—$_speedMultiplier',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
                _speedDemoButton(
                  icon: AppIcons.add_rounded,
                  enabled: _speedMultiplier < 10,
                  onTap: () => setState(() => _speedMultiplier++),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _speedDemoButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEAF2FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? const Color(0xFF0066FF) : Colors.grey[400],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusCheckTimer?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// After "Оғози сафар": frame A+B on screen, then zoom in on A once the
  /// assistant has started its announcement.
  Future<void> _checkPendingRouteFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('route_fit_pending') ?? false;
    if (!pending || !mounted) return;
    final from = _routeStart;
    final to = _routeEnd;
    if (from == null || to == null || !mounted) return;
    await prefs.setBool('route_fit_pending', false);
    _fitRouteBounds(from, to);
    // Give the assistant time to begin speaking, then zoom onto point A.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _focusOnStart(from);
    });
  }

  /// Picks a zoom that keeps both cities visible while getting as close as
  /// possible (the route never disappears from the edges of the map).
  void _fitRouteBounds(LatLng a, LatLng b) {
    final halfKm = const Distance().as(LengthUnit.Kilometer, a, b) / 2;
    final double zoom = halfKm <= 8
        ? 14
        : halfKm <= 20
        ? 12
        : halfKm <= 45
        ? 10
        : halfKm <= 110
        ? 8
        : 6;
    _zoom = zoom;
    _mapController.move(
      LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2),
      _zoom,
    );
  }

  /// Zooms the camera right onto the start city (marker A).
  void _focusOnStart(LatLng start) {
    _zoom = 15;
    _mapController.move(start, 15);
  }

  void _changeZoom(double difference) {
    _zoom = (_zoom + difference).clamp(3, 18).toDouble();
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _goToInitialLocation() {
    _zoom = 13;
    setState(() => _selectedLocation = _initialLocation);
    _mapController.move(_initialLocation, _zoom);
  }

  Future<void> _searchPlace([String? value]) async {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'tj',
        'q': query,
      });
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'InterTaxi/1.0 (com.intertaxi.intertaxi)',
          'Accept-Language': 'tg,ru;q=0.9,en;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ҷустуҷӯ дастнорас аст');
      }

      final places = (jsonDecode(response.body) as List)
          .map(
            (item) => _PlaceSearchResult.fromJson(item as Map<String, dynamic>),
          )
          .where((item) => item.location != null)
          .toList();

      if (!mounted) return;
      setState(() => _searchResults = places);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _searchError =
            'Ҷой ёфт нашуд. Аз нав кӯшиш кунед.',
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_PlaceSearchResult result) {
    final location = result.location!;
    _searchController.text = result.name;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = location;
      _searchResults = [];
    });
    _zoom = 15;
    _mapController.move(location, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialLocation,
            initialZoom: 13,
            maxZoom: 18,
            minZoom: 3,
            onTap: (_, point) => setState(() => _selectedLocation = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.intertaxi.app',
              maxNativeZoom: 19,
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF0066FF),
                    strokeWidth: 6,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: _routeStart != null && _routeEnd != null
                  ? [
                      _routeMarker(_routeStart!, Colors.green, 'Рђ'),
                      _routeMarker(_routeEnd!, Colors.red, 'Р‘'),
                      if (_carPosition != null)
                        Marker(
                          point: _carPosition!,
                          width: 48,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 5),
                              ],
                            ),
                            child: const Icon(
                              AppIcons.local_taxi_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ]
                  : [
                      Marker(
                        point: _selectedLocation,
                        width: 54,
                        height: 54,
                        child: const Icon(
                          AppIcons.location_on_rounded,
                          size: 54,
                          color: Color(0xFF0066FF),
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 5),
                          ],
                        ),
                      ),
                    ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(top: 18, right: 16, child: _buildSpeedIndicator()),
        if (_searchResults.isNotEmpty || _searchError != null)
          Positioned(
            top: 82,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 5,
              child: _searchError != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _searchError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            AppIcons.location_on_outlined,
                            color: Color(0xFF0066FF),
                          ),
                          title: Text(
                            result.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
            ),
          ),

        // Route info card: distance & duration
        if (_routeDistance != null && _routeDuration != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Distance
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0066FF,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.straighten_rounded,
                                size: 20,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.translate('Масофа'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _routeDistance!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(width: 1, height: 32, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      // Duration
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.access_time_rounded,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.translate('Вақт'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _routeDuration!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Traveled distance (only when trip started)
                  if (_tripStarted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.route_rounded,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.translate(
                                  'Масофаи тайкарда',
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                AppLocalizations.translate(
                                  '${_traveledDistance.toStringAsFixed(1)} РєРј',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_routeStartName != null && _routeEndName != null)
          Positioned(
            left: 16,
            right: 84,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.trip_origin,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _routeStartName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(AppIcons.arrow_forward_rounded, size: 18),
                  ),
                  const Icon(
                    AppIcons.location_on_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _routeEndName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_tripStarted)
          Positioned(
            right: 16,
            bottom: 104,
            child: SizedBox(
              width: 148,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _isEndingTrip ? null : _endTrip,
                icon: const Icon(AppIcons.stop_circle_outlined),
                label: Text(
                  _isEndingTrip
                      ? '...'
                      : AppLocalizations.translate('Анҷоми сафар'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 28,
          child: _MapControlButton(
            icon: AppIcons.my_location_rounded,
            onPressed: _goToInitialLocation,
          ),
        ),
      ],
    );
  }

  Marker _routeMarker(LatLng point, Color color, String label) {
    return Marker(
      point: point,
      width: 42,
      height: 42,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchResult {
  final String name;
  final LatLng? location;

  const _PlaceSearchResult({required this.name, required this.location});

  factory _PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return _PlaceSearchResult(
      name: json['display_name'] as String? ?? 'Ҷойи номаълум',
      location:
          double.tryParse(json['lat']?.toString() ?? '') != null &&
              double.tryParse(json['lon']?.toString() ?? '') != null
          ? LatLng(
              double.parse(json['lat'].toString()),
              double.parse(json['lon'].toString()),
            )
          : null,
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF0066FF)),
        ),
      ),
    );
  }
}

class _DriverStat {
  final IconData icon;
  final String label;
  final String value;

  const _DriverStat({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ProfileRatingBadge extends StatelessWidget {
  final double rating;

  const _ProfileRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.star_rounded, color: Color(0xFFFFD166), size: 19),
          const SizedBox(width: 4),
          Text(
            rating == 0 ? 'вЂ”' : rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAboutSheet extends StatelessWidget {
  const _DriverAboutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFD5DCE7),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            const InterTaxiLogo(size: 82, showTagline: true),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.translate(
                'InterTaxi — Барномаи муосири такси ва сафарҳои байнишаҳрӣ дар Тоҷикистон.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1D2735),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _AboutFeature(
              icon: AppIcons.route_rounded,
              text: AppLocalizations.translate(
                'Эълон ва идоракунии сафарҳои байнишаҳрӣ',
              ),
            ),
            _AboutFeature(
              icon: AppIcons.map_rounded,
              text: AppLocalizations.translate(
                'Харитаи зинда ва масири воқеии роҳ',
              ),
            ),
            _AboutFeature(
              icon: AppIcons.people_alt_rounded,
              text: AppLocalizations.translate(
                'Пайвасти мустақими ронанда ва мусофир',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Developed by InterTaxi Team',
              style: TextStyle(
                color: Color(0xFF7A8798),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(AppLocalizations.translate('Пӯшидан')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AboutFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4F5D6F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideHistorySheet extends StatelessWidget {
  const _DriverRideHistorySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFD5DCE7),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.translate('Таърихи сафарҳо'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172235),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            child: FutureBuilder<List<Order>>(
              future: loadOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? const <Order>[];
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.route_rounded,
                          size: 52,
                          color: Colors.grey[350],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.translate(
                            'Ҳанӯз сафар сабт нашудааст',
                          ),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final departure = DateTime.tryParse(order.departureTime);
                    final isCompleted =
                        departure != null && departure.isBefore(DateTime.now());
                    final status = isCompleted
                        ? 'Анҷом ёфт'
                        : 'Фаъол';
                    final statusColor = isCompleted
                        ? const Color(0xFF718096)
                        : const Color(0xFF168A52);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5EAF1)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A173B73),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              AppIcons.route_rounded,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.fromLocation} в†’ ${order.toLocation}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D2735),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.translate(
                                    '${order.price} • ${order.seats} ҷой',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetProfileAndRestart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Танзимот')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.translate(
                'Танзимоти ҳисоби корбар',
              ),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.translate(
                'Бо зер кардани тугмаи зерин, ҳамаи маълумоти профил аз нав оғоз карда мешавад.',
              ),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _resetProfileAndRestart(context),
                icon: const Icon(AppIcons.restart_alt_rounded),
                label: Text(
                  AppLocalizations.translate(
                    'Аз нав оғоз кардан',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ServerSettingsScreen(),
                  ),
                ),
                icon: const Icon(AppIcons.dns_rounded),
                label: Text(AppLocalizations.translate('Сервер')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0066FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  String? _selectedCarBrand;
  String? _selectedCarColor;
  bool _isLoading = false;

  final List<String> _carColors = [
    'Сабз',
    'Сафед',
    'РЎРёС‘Ті',
    'РЎСѓСЂС…',
    'Кабуд',
    'Зард',
    'Нилӯфар',
    'Беж',
    'Кул',
    'Тилоӣ',
  ];

  @override
  void dispose() {
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Widget _buildLicensePlateBox({
    required TextEditingController controller,
    required int startIndex,
    required int length,
    required bool isNumber,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLength: length,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        decoration: InputDecoration(counterText: '', border: InputBorder.none),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Only allow numbers for first and last sections
            if (isNumber) {
              final filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
              return TextEditingValue(
                text: filtered.substring(0, min(filtered.length, length)),
                selection: newValue.selection,
              );
            } else {
              // Only allow letters for middle section
              final filtered = newValue.text.replaceAll(
                RegExp(r'[^A-Za-z]'),
                '',
              );
              return TextEditingValue(
                text: filtered
                    .substring(0, min(filtered.length, length))
                    .toUpperCase(),
                selection: newValue.selection,
              );
            }
          }),
        ],
      ),
    );
  }

  Future<void> _saveDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final originalFirstName = prefs.getString('user_first_name') ?? '';
    final originalLastName = prefs.getString('user_last_name') ?? '';
    final originalBirthYear = prefs.getString('user_birth_year') ?? '';

    await prefs.setString('app_session_version', _appSessionVersion);
    await prefs.setString('user_name', widget.passengerName);
    await prefs.setString('user_phone', widget.passengerPhone);
    await prefs.setString('user_role', 'driver');
    await prefs.setString(
      'user_first_name',
      originalFirstName.isNotEmpty
          ? originalFirstName
          : widget.passengerName.split(RegExp(r'\s+')).first,
    );
    await prefs.setString(
      'user_last_name',
      originalLastName.isNotEmpty
          ? originalLastName
          : widget.passengerName.split(RegExp(r'\s+')).skip(1).join(' '),
    );
    await prefs.setString('user_birth_year', originalBirthYear);

    if (_selectedCarBrand != null) {
      await prefs.setString('driver_car_brand', _selectedCarBrand!);
    }
    if (_selectedCarColor != null) {
      await prefs.setString('driver_car_color', _selectedCarColor!);
    }
    if (_carModelController.text.trim().isNotEmpty) {
      await prefs.setString(
        'driver_car_model',
        _carModelController.text.trim(),
      );
    }
    if (_licensePlateController.text.trim().isNotEmpty) {
      await prefs.setString(
        'driver_plate_number',
        _licensePlateController.text.trim(),
      );
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          setState(() => _isLoading = false);
          await _saveDriverProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverHomeScreen(
                driverName: widget.passengerName,
                driverPhone: widget.passengerPhone,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.translate('Маълумоти мошин'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: LightGlassColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.translate(
                      'Маълумоти мошини худро ворид кунед',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: LightGlassColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Car Brand Selection
                  GestureDetector(
                    onTap: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarBrandSelectionScreen(
                            brands: supportedCarBrands,
                            selectedBrand: _selectedCarBrand,
                          ),
                        ),
                      );
                      if (selected != null) {
                        setState(() => _selectedCarBrand = selected);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedCarBrand != null
                              ? const Color(0xFF0066FF)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        color: LightGlassColors.surface,
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedCarBrand ??
                                'Маркаи мошинро интихоб кунед',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCarBrand != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            AppIcons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Car Model Input
                  TextFormField(
                    controller: _carModelController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.translate(
                          'Модели мошинро ворид кунед',
                        );
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.translate(
                        'Модели мошин',
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // License Plate Number (Format: 4 digits + 2 letters + 2 digits)
                  TextFormField(
                    controller: _licensePlateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.translate(
                          'Рақами давлатиро ворид кунед',
                        );
                      }
                      if (value.length != 8) {
                        return AppLocalizations.translate(
                          'Рақам бояд 8 аломат бошад (масалан: 1111AA01)',
                        );
                      }
                      // Format: 4 digits + 2 letters + 2 digits
                      final regex = RegExp(r'^\d{4}[A-Z]{2}\d{2}$');
                      if (!regex.hasMatch(value.toUpperCase())) {
                        return AppLocalizations.translate(
                          'Формат: 4 рақам + 2 ҳарф + 2 рақам (масалан: 1111AA01)',
                        );
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.translate(
                        'Рақами давлатӣ',
                      ),
                      border: OutlineInputBorder(),
                      hintText: AppLocalizations.translate(
                        'Масалан: 1111AA01',
                      ),
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        // Remove all non-alphanumeric characters
                        String filtered = newValue.text.replaceAll(
                          RegExp(r'[^A-Za-z0-9]'),
                          '',
                        );

                        // Convert to uppercase
                        filtered = filtered.toUpperCase();

                        // Smart formatting: automatically format as user types
                        if (filtered.isNotEmpty) {
                          // First 4 characters: numbers only
                          if (filtered.length <= 4) {
                            // Keep only numbers for first section
                            filtered = filtered.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                          } else if (filtered.length <= 6) {
                            // First 4 are numbers, next 2 are letters
                            final numbers = filtered
                                .substring(0, 4)
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            final letters = filtered
                                .substring(4)
                                .replaceAll(RegExp(r'[^A-Z]'), '');
                            filtered = numbers + letters;
                          } else {
                            // 4 numbers + 2 letters + remaining numbers
                            final numbers1 = filtered
                                .substring(0, 4)
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            final letters = filtered
                                .substring(4, min(6, filtered.length))
                                .replaceAll(RegExp(r'[^A-Z]'), '');
                            final numbers2 = filtered
                                .substring(6)
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            filtered = numbers1 + letters + numbers2;
                          }
                        }

                        // Limit to 8 characters
                        final limited = filtered.substring(
                          0,
                          min(filtered.length, 8),
                        );

                        return TextEditingValue(
                          text: limited,
                          selection: newValue.selection,
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Car Color Selection
                  GestureDetector(
                    onTap: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarColorSelectionScreen(
                            colors: _carColors,
                            selectedColor: _selectedCarColor,
                          ),
                        ),
                      );
                      if (selected != null) {
                        setState(() => _selectedCarColor = selected);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedCarColor != null
                              ? const Color(0xFF0066FF)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          LightGlassRadius.field,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedCarColor ??
                                'Ранги мошинро интихоб кунед',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCarColor != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            AppIcons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppLocalizations.translate(
                                'Идома додан',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
