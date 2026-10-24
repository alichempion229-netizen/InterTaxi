import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

// just_audio exposes in-memory sources through this experimental API.
// ignore_for_file: experimental_member_use

/// Plays short ElevenLabs announcements without blocking UI workflows.
class TTSService {
  static final TTSService instance = TTSService._();

  static const _apiKey = String.fromEnvironment(
    'ELEVENLABS_API_KEY',
    defaultValue: 'sk_549c16001d4815afcc26604602b8766df91fdf7481351c82',
  );
  static const _voiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: 'cgSgspJ2msm6clMCkdW9',
  );
  static const _modelId = 'eleven_multilingual_v2';
  static const _apiBaseUrl = 'https://api.elevenlabs.io/v1/text-to-speech';

  final AudioPlayer _player = AudioPlayer();
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  Future<void> _playerOperation = Future<void>.value();
  int _announcementGeneration = 0;

  TTSService._() {
    _playerStateSubscription = _player.playerStateStream.listen(
      (state) => _setSpeaking(
        state.playing && state.processingState != ProcessingState.completed,
      ),
      onError: (_) => _setSpeaking(false),
    );
  }

  Stream<bool> get isSpeakingStream => _speakingController.stream.distinct();

  void _setSpeaking(bool value) {
    if (!_speakingController.isClosed) _speakingController.add(value);
  }

  Future<void> announceTripStart({
    required String driverName,
    required String fromCity,
    required String toCity,
  }) {
    final announcement =
        'Салому алейкум мусофирони гиромӣ! Ронандаи шумо $driverName. '
        'Сафари шумо аз шаҳри $fromCity ба $toCity оғоз ёфт. '
        'Сафари бехатар хоҳонам!';

    return _enqueueSpeech(announcement);
  }

  Future<void> announceSpeedWarning() {
    return _enqueueSpeech(
      'Лутфан оҳиста ронед. Шумо аз меъёр зиёд ронда истодаед.',
    );
  }

  /// Generates and plays a detailed passenger welcome for the selected route.
  Future<void> announcePassengerTrip({
    required String startCity,
    required String finishCity,
    required double distanceKm,
    required int durationMinutes,
    int? priceSomoni,
    int? availableSeats,
  }) {
    final distance = distanceKm.toStringAsFixed(1);
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final duration = hours > 0
        ? '$hours соат $minutes дақиқа'
        : '$minutes дақиқа';
    final arrival = DateTime.now().add(Duration(minutes: durationMinutes));
    final arrivalTime =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
    final priceText = priceSomoni == null
        ? ''
        : ' Нархи сафар $priceSomoni сомонӣ мебошад.';
    final seatsText = availableSeats == null
        ? ''
        : ' Ҷойҳои холӣ: $availableSeats.';
    final announcement =
        '''РҐСѓС€ РѕРјР°РґРµРґ, РјСѓСЃРѕС„РёСЂРѕРЅРё Р°Р·РёР·!

РњР°РЅ Р°СЃСЃРёСЃС‚РµРЅС‚Рё Р·РµТіРЅРёРё С€СѓРјРѕ ТіР°СЃС‚Р°Рј. РРјСЂУЇР· С€СѓРјРѕ Т›Р°СЂРѕСЂ РіРёСЂРёС„С‚РµРґ, РєРё Р°Р· $startCity Р±Р° $finishCity СЃР°С„Р°СЂ РєСѓРЅРµРґ.

РњР°СЃРѕС„Р°Рё СѓРјСѓРјРёРё СЂРѕТі $distance РєРёР»РѕРјРµС‚СЂ Р±СѓРґР°, РґР°РІРѕРјРЅРѕРєРёРё СЃР°С„Р°СЂ С‚Р°Т›СЂРёР±Р°РЅ $duration РјРµР±РѕС€Р°Рґ.$priceText$seatsText Р‘Рѕ РЅР°Р·Р°СЂРґРѕС€С‚Рё РІР°Т›С‚Рё СЃР°С„Р°СЂ, РјРѕ С‚Р°Т›СЂРёР±Р°РЅ СЃРѕР°С‚Рё $arrivalTime Р±Р° $finishCity РјРµСЂР°СЃРµРј.

Р‘Р° С€СѓРјРѕ СЃР°С„Р°СЂРё С…СѓС€Сѓ СЂРѕТіР°С‚ РІР° СЂРѕТіРё Р±РµС…Р°С‚Р°СЂ С‚Р°РјР°РЅРЅРѕ РґРѕСЂР°Рј. Р›СѓС‚С„Р°РЅ, РєР°РјР°СЂР±Р°РЅРґРё Р±РµС…Р°С‚Р°СЂРёРё С…СѓРґСЂРѕ Р±Р°РЅРґРµРґ РІР° Р°Р· СЃР°С„Р°СЂ Р»Р°Р·Р·Р°С‚ Р±Р°СЂРµРґ.

РЎР°С„Р°СЂРё С…СѓС€ РІР° СЂРѕТіРё СЃР°С„РµРґ!''';

    return _enqueueSpeech(announcement);
  }

  Future<void> _enqueueSpeech(String text) {
    final generation = ++_announcementGeneration;
    _queuePlayerOperation(() => _player.stop());
    return _speak(text, generation);
  }

  Future<void> _speak(String text, int generation) async {
    if (_apiKey.isEmpty) {
      debugPrint(
        'ElevenLabs TTS skipped: pass ELEVENLABS_API_KEY with --dart-define.',
      );
      return;
    }

    try {
      final preparedText = _prepareTajikText(text);
      debugPrint('ElevenLabs TTS request started.');
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/$_voiceId'),
        headers: {'xi-api-key': _apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': preparedText,
          'model_id': _modelId,
          'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final details = response.body.substring(
          0,
          response.body.length.clamp(0, 300),
        );
        if (response.statusCode == 401 ||
            response.statusCode == 402 ||
            response.statusCode == 429) {
          debugPrint(
            'ElevenLabs TTS credit/auth/rate limit error '
            '${response.statusCode}: $details',
          );
        } else {
          debugPrint(
            'ElevenLabs TTS HTTP error ${response.statusCode}: $details',
          );
        }
        return;
      }

      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) {
        debugPrint('ElevenLabs TTS error: response contained no audio.');
        return;
      }

      if (generation != _announcementGeneration) return;

      await _queuePlayerOperation(() async {
        if (generation != _announcementGeneration) return;
        await _player.stop();
        if (generation != _announcementGeneration) return;
        await _player.setAudioSource(_Mp3BytesSource(audioBytes));
        await _player.setVolume(1.0);
        await _player.play();
        debugPrint(
          'ElevenLabs TTS request succeeded; playing ${audioBytes.length} bytes.',
        );
      });
    } catch (error) {
      // Speech is an enhancement; network/audio failures must never interrupt a trip.
      debugPrint('ElevenLabs TTS unavailable: $error');
    }
  }

  String _prepareTajikText(String text) {
    var prepared = text;

    const months = <String, String>{
      '01': 'январи',
      '02': 'феврали',
      '03': 'марти',
      '04': 'апрели',
      '05': 'майи',
      '06': 'РёСЋРЅРё',
      '07': 'июли',
      '08': 'августи',
      '09': 'сентябри',
      '10': 'октябри',
      '11': 'ноябри',
      '12': 'декабри',
    };

    prepared = prepared.replaceAllMapped(
      RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b'),
      (match) =>
          '${_numberToTajikWords(int.parse(match.group(3)!))} '
          '${months[match.group(2)!] ?? match.group(2)!} соли '
          '${_numberToTajikWords(int.parse(match.group(1)!))}',
    );

    prepared = prepared.replaceAllMapped(
      RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b'),
      (match) =>
          'соати ${_numberToTajikWords(int.parse(match.group(1)!))} ва '
          '${_numberToTajikWords(int.parse(match.group(2)!))} дақиқа',
    );

    prepared = prepared.replaceAllMapped(
      RegExp(
        r'(?<![\p{L}\d])(\d+(?:[.,]\d+)?)\s*(?:СЃРЅРё|СЃ\.РЅ\.?|СЃ\.?|СЃРѕРј\.?)\b',
        unicode: true,
      ),
      (match) =>
          '${_numberWithDecimalToTajikWords(match.group(1)!)} СЃРѕРјРѕРЅУЈ',
    );

    prepared = prepared.replaceAllMapped(
      RegExp(r'(?<![\p{L}\d])(\d+(?:[.,]\d+)?)(?![\p{L}])', unicode: true),
      (match) => _numberWithDecimalToTajikWords(match.group(1)!),
    );

    return prepared.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _numberWithDecimalToTajikWords(String value) {
    final parts = value.replaceAll(',', '.').split('.');
    final whole = _numberToTajikWords(int.parse(parts.first));
    if (parts.length == 1) return whole;
    final fraction = parts[1]
        .split('')
        .map((digit) => _numberToTajikWords(int.parse(digit)))
        .join(' ');
    return '$whole нуқта $fraction';
  }

  String _numberToTajikWords(int number) {
    if (number == 0) return 'СЃРёС„СЂ';
    if (number < 0) return 'манфӣ ${_numberToTajikWords(-number)}';
    if (number < 100) return _underOneHundredToTajikWords(number);
    if (number < 1000) {
      final hundreds = number ~/ 100;
      final remainder = number % 100;
      final word = hundreds == 1
          ? 'сад'
          : '${_underOneHundredToTajikWords(hundreds)}сад';
      return remainder == 0
          ? word
          : '$word ва ${_numberToTajikWords(remainder)}';
    }
    if (number < 1000000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      final word = thousands == 1
          ? 'ҳазор'
          : '${_numberToTajikWords(thousands)} ҳазор';
      return remainder == 0
          ? word
          : '$word ва ${_numberToTajikWords(remainder)}';
    }
    final millions = number ~/ 1000000;
    final remainder = number % 1000000;
    final word = millions == 1
        ? 'як миллион'
        : '${_numberToTajikWords(millions)} миллион';
    return remainder == 0
        ? word
        : '$word ва ${_numberToTajikWords(remainder)}';
  }

  String _underOneHundredToTajikWords(int number) {
    const units = [
      '',
      'СЏРє',
      'РґСѓ',
      'се',
      'С‡РѕСЂ',
      'панҷ',
      'шаш',
      'ҳафт',
      'ҳашт',
      'РЅУЇТі',
    ];
    const tens = [
      '',
      'даҳ',
      'бист',
      'СЃУЈ',
      'чил',
      'панҷоҳ',
      'шаст',
      'ҳафтод',
      'ҳаштод',
      'навад',
    ];
    const teens = [
      'ёздаҳ',
      'дувоздаҳ',
      'сенздаҳ',
      'чордаҳ',
      'понздаҳ',
      'шонздаҳ',
      'ҳафдаҳ',
      'ҳаждаҳ',
      'нуздаҳ',
    ];
    if (number < 10) return units[number];
    if (number == 10) return tens[1];
    if (number < 20) return teens[number - 11];
    final ten = tens[number ~/ 10];
    final unit = number % 10;
    return unit == 0 ? ten : '$tenСѓ ${units[unit]}';
  }

  Future<void> stop() async {
    _announcementGeneration++;
    _setSpeaking(false);
    await _queuePlayerOperation(() => _player.stop());
  }

  Future<void> dispose() async {
    await _playerStateSubscription.cancel();
    await _player.dispose();
    await _speakingController.close();
  }

  Future<void> _queuePlayerOperation(Future<void> Function() operation) {
    _playerOperation = _playerOperation
        .catchError((_) {})
        .then((_) => operation());
    return _playerOperation;
  }
}

class _Mp3BytesSource extends StreamAudioSource {
  _Mp3BytesSource(this._bytes);

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      stream: Stream.value(_bytes.sublist(rangeStart, rangeEnd)),
      contentType: 'audio/mpeg',
    );
  }
}
