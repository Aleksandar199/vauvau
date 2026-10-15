import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Short in-app chime for incoming chat messages.
abstract class MessageSoundPlayer {
  Future<void> play();

  void dispose();
}

class AudioMessageSoundPlayer implements MessageSoundPlayer {
  static const String assetPath = 'sounds/message.wav';

  AudioPlayer? _player;

  @override
  Future<void> play() async {
    try {
      final player = _player ??= await _createPlayer();
      await player.stop();
      await player.play(AssetSource(assetPath), volume: 0.8);
    } catch (error) {
      debugPrint('Message sound failed: $error');
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    // Must not pause the user's music and must stay quiet in silent mode.
    await player.setAudioContext(
      AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
      ).build(),
    );
    return player;
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

final messageSoundPlayerProvider = Provider<MessageSoundPlayer>((ref) {
  final player = AudioMessageSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
});
