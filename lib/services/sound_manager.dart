import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();

  bool isMusicPlaying = false; // Made public for checking state

  Future<void> startBackgroundMusic() async {
    if (isMusicPlaying) return;
    try {
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.play(AssetSource('sound-effects/background.mp3'), volume: 0.4); // Lowered volume
      isMusicPlaying = true;
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _backgroundMusicPlayer.stop();
    isMusicPlaying = false;
  }
  
  Future<void> pauseBackgroundMusic() async {
    if (!isMusicPlaying) return;
    await _backgroundMusicPlayer.pause();
    isMusicPlaying = false;
  }

  Future<void> resumeBackgroundMusic() async {
    if (isMusicPlaying) return; // Already playing
    await _backgroundMusicPlayer.resume();
    isMusicPlaying = true;
  }

  Future<void> toggleMusic() async {
    if (isMusicPlaying) {
      await _backgroundMusicPlayer.pause();
      isMusicPlaying = false;
    } else {
      await _backgroundMusicPlayer.resume();
      isMusicPlaying = true;
    }
  }

  Future<void> playClickSound() async {
    try {
      if (_soundEffectPlayer.state == PlayerState.playing) {
        await _soundEffectPlayer.stop();
      }
      await _soundEffectPlayer.setReleaseMode(ReleaseMode.release);
      await _soundEffectPlayer.play(AssetSource('sound-effects/pop.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing click sound: $e");
    }
  }
  
  void dispose() {
    _backgroundMusicPlayer.dispose();
    _soundEffectPlayer.dispose();
  }
}
