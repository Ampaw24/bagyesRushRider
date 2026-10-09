import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';

/// The ring that plays while an incoming delivery offer is on screen —
/// a looping custom tone plus a pulsing vibration, until [stop].
///
/// Plugin-only, like `RiderLocationService`: it knows nothing about offers,
/// Riverpod or widgets. `RiderIncomingOfferListener` decides when to ring.
///
/// The sound is `assets/sounds/new_order.mp3`. The same file ships as the
/// Android notification-channel sound (`res/raw/new_order.mp3`) and, converted,
/// as the iOS push sound (`Runner/new_order.caf`), so an offer sounds the same
/// whether the app is open or the push wakes it.
class OrderAlertService {
  static const _asset = 'sounds/new_order.mp3';
  static const _vibrationPulse = Duration(milliseconds: 1200);

  AudioPlayer? _player;
  Timer? _vibration;
  bool _ringing = false;

  bool get isRinging => _ringing;

  /// Idempotent: a second call while already ringing does nothing.
  Future<void> start() async {
    if (_ringing) return;
    _ringing = true;

    _vibration = Timer.periodic(_vibrationPulse, (_) {
      HapticFeedback.heavyImpact();
    });
    HapticFeedback.heavyImpact();

    try {
      final player = _player ??= AudioPlayer();
      // Plays as a ringtone: follows the ringer volume on Android, and sounds
      // even with the iOS silent switch on, ducking other audio meanwhile.
      await player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
      ));
      await player.setReleaseMode(ReleaseMode.loop);
      // Stopped before the awaits above finished — don't start a ring nobody
      // is listening for.
      if (!_ringing) return;
      await player.play(AssetSource(_asset));
    } catch (e, s) {
      // No sound must never block the dialog: the vibration and the dialog
      // itself still tell the rider an offer arrived.
      appLogger.e('[OrderAlert] could not play tone', error: e, stackTrace: s);
    }
  }

  /// Idempotent.
  Future<void> stop() async {
    if (!_ringing) return;
    _ringing = false;
    _vibration?.cancel();
    _vibration = null;
    try {
      await _player?.stop();
    } catch (e) {
      appLogger.w('[OrderAlert] could not stop tone: $e');
    }
  }
}
