import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

const double kVoiceSpeed = 1.15;
const bool kArrivalUses12Hour = false;
const Duration kTrimEnd = Duration(milliseconds: 150);
const Duration kTrimStart = Duration(milliseconds: 40);

class TripVoiceAssistant {
  TripVoiceAssistant._();

  static final TripVoiceAssistant instance = TripVoiceAssistant._();

  static const _greeting = 'ассалому алекум.m4a';
  static const _greetingNext = 'хурчандем.m4a';
  static const _today = 'имруз мо.m4a';
  static const _city = 'шахри.m4a';
  static const _district = 'нохия.m4a';
  static const _beautiful = 'зебои.m4a';
  static const _moving = 'харакат.m4a';
  static const _estimated = 'вакти тахминии сафар.m4a';
  static const _approximately = 'будан такрибан_1.m4a';
  static const _arrivalTo = 'ба.m4a';
  static const _arrive = 'мерасем.m4a';
  static const _closing = 'пас рохат шинед.m4a';
  static const _hour = 'соат.m4a';
  static const _hourAnd = 'соату.m4a';
  static const _minute = 'дакика.m4a';

  static const Map<int, String> _smallNumbers = {
    1: 'як.m4a', 2: 'ду.m4a', 3: 'се.m4a', 4: 'чор.m4a',
    5: 'панч.m4a', 6: 'шаш.m4a', 7: 'хафт.m4a', 8: 'хащт.m4a',
    9: 'нух.m4a', 10: 'дах.m4a', 11: 'ездах.m4a', 12: 'дувоздах.m4a',
    13: '13.m4a', 14: '14.m4a', 15: '15.m4a', 16: '16.m4a',
    17: '17.m4a', 18: '18.m4a', 19: '19.m4a',
  };

  static const Map<int, String> _tens = {
    20: 'бисту.m4a', 30: 'сиву.m4a', 40: 'чилу.m4a',
    50: 'панчоху.m4a', 60: 'шасту.m4a', 70: 'хафтоду.m4a',
    80: 'хаштоду.m4a', 90: 'наваду.m4a',
  };

  static const Map<int, String> _hundreds = {
    100: 'саду.m4a', 200: 'дусаду.m4a', 300: 'сесаду.m4a',
    400: 'чорсаду.m4a', 500: 'панчсаду.m4a', 600: 'шашсаду.m4a',
    700: 'хафтсаду.m4a', 800: 'хаштсаду.m4a', 900: 'нухсаду.m4a',
  };

  static const Map<String, String> _destinations = {
    'душанбе': '',
    'хучанд': 'хучанд.m4a',
    'бохтар': 'бохтар.m4a',
    'кулоб': 'кулоб.m4a',
    'хоруг': 'хоруг.m4a',
    'турсунзода': 'турсунзода.m4a',
    'вахдат': 'вахдат.m4a',
    'хисор': 'хисор.m4a',
    'панчакент': 'панчакент.m4a',
    'истаравшан': 'истаравшан.m4a',
    'исфара': 'исфара.m4a',
    'конибодом': 'конибодом.m4a',
    'гулистон': 'гулистон.m4a',
    'бустон': 'бустон.m4a',
    'истиклол': 'истиклол.m4a',
    'норак': 'норак.m4a',
    'левакант': 'левакант.m4a',
    'рогун': 'рогун.m4a',
  };

  static const Set<String> _districtNames = {
    'айни', 'ашт', 'бобочон гафуров', 'деваштич', 'зафаробод',
    'кухистони мастчох', 'мастчох', 'спитамен', 'шахристон',
    'чаббор расулов', 'ванч', 'дарвоз', 'ишкошим', 'мургаб',
    'рошткала', 'рушон', 'шугнон', 'балчувон', 'вахш', 'восе',
    'дангара', 'дусти', 'чайхун', 'чалолиддини балхи',
    'мир сайид алии хамадони', 'носири хусрав', 'панч', 'кубодиён',
    'кушониён', 'хамадониобод', 'темурмалик', 'фархор', 'ховалинг',
    'хуросон', 'шахритус', 'шамсиддин шохин', 'явон',
    'абдурахмони чоми', 'варзоб', 'лахш', 'нуробод', 'рашт',
    'рудаки', 'сангвор', 'точикобод', 'файзобод', 'шахринав',
  };

  final AudioPlayer _player = AudioPlayer(handleAudioSessionActivation: false);
  AudioPlayer? _fallbackPlayer;
  final Map<String, Duration> _clipDurations = {};
  final Set<String> _checkedClipDurations = {};
  int _runId = 0;
  bool _disposed = false;

  bool get isPlaying => _player.playing || (_fallbackPlayer?.playing ?? false);

  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ӯ', 'у')
      .replaceAll('ӣ', 'и')
      .replaceAll('ҳ', 'х')
      .replaceAll('ҷ', 'ч')
      .replaceAll('қ', 'к')
      .replaceAll('ғ', 'г')
      .replaceAll('ё', 'е');

  String? _destinationClip(String destination) {
    final file = _destinations[normalize(destination)];
    return file == null || file.isEmpty ? null : file;
  }

  Set<String> get _allClipFiles => {
    _greeting,
    _greetingNext,
    _today,
    _city,
    _district,
    _beautiful,
    _moving,
    _estimated,
    _approximately,
    _arrivalTo,
    _arrive,
    _closing,
    _hour,
    _hourAnd,
    _minute,
    ..._smallNumbers.values,
    ..._tens.values,
    ..._hundreds.values,
    ..._destinations.values.where((file) => file.isNotEmpty),
  };

  AudioSource _sourceFor(String file) {
    final duration = _clipDurations[file];
    if (duration == null || duration <= kTrimStart + kTrimEnd) {
      return AudioSource.asset('assets/audios/$file');
    }
    return ClippingAudioSource(
      child: AudioSource.asset('assets/audios/$file'),
      start: kTrimStart,
      end: duration - kTrimEnd,
    );
  }

  List<String> numberClips(int number) {
    if (number < 1 || number > 999) return const [];
    if (number < 20) return [_smallNumbers[number]!];
    if (number < 100) {
      final tens = _tens[(number ~/ 10) * 10];
      final unit = number % 10 == 0 ? null : _smallNumbers[number % 10];
      if (tens == null || (number % 10 != 0 && unit == null)) return const [];
      return [tens, if (unit != null) unit];
    }
    final hundred = _hundreds[(number ~/ 100) * 100];
    final remainder = number % 100;
    final rest = remainder == 0 ? const <String>[] : numberClips(remainder);
    if (hundred == null || (remainder != 0 && rest.isEmpty)) return const [];
    return [hundred, ...rest];
  }

  List<String> _makePlaylist(String destination, int durationMinutes) {
    final destinationClip = _destinationClip(destination);
    final clips = <String>[
      _greeting, _greetingNext, _today,
      _districtNames.contains(normalize(destination)) ? _district : _city,
      _beautiful,
      if (destinationClip != null) destinationClip,
      _moving,
    ];
    if (durationMinutes > 0) {
      clips.add(_estimated);
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (hours > 0) {
        clips.addAll(numberClips(hours));
        if (minutes > 0) {
          clips.add(_hourAnd);
          clips.addAll(numberClips(minutes));
          clips.add(_minute);
        } else {
          clips.add(_hour);
        }
      } else {
        clips.addAll(numberClips(minutes));
        clips.add(_minute);
      }
      clips.add(_approximately);
      final arrival = DateTime.now().add(Duration(minutes: durationMinutes));
      final hour = kArrivalUses12Hour
          ? (arrival.hour % 12 == 0 ? 12 : arrival.hour % 12)
          : (arrival.hour == 0 ? 24 : arrival.hour);
      clips.addAll(numberClips(hour));
      if (arrival.minute > 0) {
        clips.addAll(numberClips(arrival.minute));
      }
      if (destinationClip != null) clips..add(_arrivalTo)..add(destinationClip);
      clips.add(_arrive);
    }
    clips.add(_closing);
    return clips;
  }

  Future<void> preload() async {
    try {
      for (final file in _allClipFiles) {
        if (!_checkedClipDurations.add(file)) continue;
        try {
          await _player.setAsset('assets/audios/$file');
          final duration = _player.duration;
          if (duration != null) _clipDurations[file] = duration;
        } catch (error) {
          if (kDebugMode) debugPrint('[TripVoiceAssistant] duration $file: $error');
        }
      }
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          useLazyPreparation: false,
          children: [
            _sourceFor(_greeting),
            _sourceFor(_greetingNext),
          ],
        ),
        preload: true,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[TripVoiceAssistant] preload: $error');
    }
  }

  Future<void> playTripStart({
    required String destination,
    required int durationMinutes,
  }) async {
    final stopwatch = Stopwatch()..start();
    stop();
    final runId = _runId;
    final clips = _makePlaylist(destination, durationMinutes);
    if (kDebugMode) debugPrint('[TripVoiceAssistant] playlist: $clips');
    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          useLazyPreparation: false,
          children: clips.map(_sourceFor).toList(),
        ),
        preload: true,
      );
      if (runId != _runId || _disposed) return;
      await _player.setSpeed(kVoiceSpeed);
      if (runId != _runId || _disposed) return;
      final started = _player.playerStateStream.firstWhere((state) => state.playing);
      unawaited(started.then((_) {
        if (kDebugMode) {
          debugPrint('[TripVoiceAssistant] first clip started in ${stopwatch.elapsed}');
        }
      }));
      unawaited(_player.play().catchError((Object error) {
        if (kDebugMode) debugPrint('[TripVoiceAssistant] playback: $error');
      }));
    } catch (error) {
      if (kDebugMode) debugPrint('[TripVoiceAssistant] playlist setup: $error');
      if (runId == _runId && !_disposed) {
        await _playFallback(clips, runId, stopwatch);
      }
    }
  }

  Future<void> _playFallback(List<String> clips, int runId, Stopwatch stopwatch) async {
    final first = AudioPlayer(handleAudioSessionActivation: false);
    final second = AudioPlayer(handleAudioSessionActivation: false);
    _fallbackPlayer = first;
    var active = first;
    var loggedStart = false;
    try {
      for (var i = 0; i < clips.length; i++) {
        if (runId != _runId || _disposed) return;
        final next = identical(active, first) ? second : first;
        try {
          await active.setAudioSource(_sourceFor(clips[i]));
          await active.setSpeed(kVoiceSpeed);
        } catch (error) {
          if (kDebugMode) debugPrint('[TripVoiceAssistant] ${clips[i]}: $error');
          continue;
        }
        final completed = active.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
        );
        _fallbackPlayer = active;
        unawaited(active.play().catchError((Object error) {
          if (kDebugMode) debugPrint('[TripVoiceAssistant] ${clips[i]}: $error');
        }));
        if (!loggedStart && kDebugMode) {
          debugPrint('[TripVoiceAssistant] first clip started in ${stopwatch.elapsed}');
          loggedStart = true;
        }
        if (i + 1 < clips.length) {
          try {
            await next.setAudioSource(_sourceFor(clips[i + 1]));
            await next.setSpeed(kVoiceSpeed);
          } catch (error) {
            if (kDebugMode) debugPrint('[TripVoiceAssistant] ${clips[i + 1]}: $error');
          }
        }
        await completed;
        if (i + 1 < clips.length) active = next;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[TripVoiceAssistant] fallback: $error');
    } finally {
      try {
        await first.dispose();
      } catch (error) {
        if (kDebugMode) debugPrint('[TripVoiceAssistant] fallback dispose: $error');
      }
      try {
        await second.dispose();
      } catch (error) {
        if (kDebugMode) debugPrint('[TripVoiceAssistant] fallback dispose: $error');
      }
      if (identical(_fallbackPlayer, first) || identical(_fallbackPlayer, second)) {
        _fallbackPlayer = null;
      }
    }
  }

  void stop() {
    _runId++;
    unawaited(_player.stop().catchError((Object error) {
      if (kDebugMode) debugPrint('[TripVoiceAssistant] stop: $error');
    }));
    final fallback = _fallbackPlayer;
    if (fallback != null) {
      unawaited(fallback.stop().catchError((Object error) {
        if (kDebugMode) debugPrint('[TripVoiceAssistant] fallback stop: $error');
      }));
    }
  }

  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
    unawaited(_player.dispose().catchError((Object error) {
      if (kDebugMode) debugPrint('[TripVoiceAssistant] dispose: $error');
    }));
    final fallback = _fallbackPlayer;
    if (fallback != null) {
      unawaited(fallback.dispose().catchError((Object error) {
        if (kDebugMode) debugPrint('[TripVoiceAssistant] fallback dispose: $error');
      }));
    }
  }
}
