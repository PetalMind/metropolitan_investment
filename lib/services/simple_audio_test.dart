import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Simple audio test service for debugging
class SimpleAudioTest {
  static final AudioPlayer _player = AudioPlayer();
  
  static Future<void> testEmailSound() async {
    if (kDebugMode) {
      print('🧪 [SimpleAudioTest] Starting...');
      print('🧪 [SimpleAudioTest] Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    }
    
    try {
      if (kIsWeb) {
        // Web specific configuration
        await _player.setPlayerMode(PlayerMode.lowLatency);
        if (kDebugMode) {
          print('🌐 [SimpleAudioTest] Web player mode set');
        }
      }
      
      // Try to play the sound
      await _player.play(AssetSource('audio/email_sound.mp3'));
      
      if (kDebugMode) {
        print('✅ [SimpleAudioTest] Audio play command sent successfully');
      }
      
      // Listen for state changes
      _player.onPlayerStateChanged.listen((PlayerState state) {
        if (kDebugMode) {
          print('🔊 [SimpleAudioTest] Player state: $state');
        }
      });
      
      // Listen for position changes
      _player.onPositionChanged.listen((Duration position) {
        if (kDebugMode) {
          print('⏱️ [SimpleAudioTest] Position: ${position.inMilliseconds}ms');
        }
      });
      
      // Listen for completion
      _player.onPlayerComplete.listen((event) {
        if (kDebugMode) {
          print('🏁 [SimpleAudioTest] Audio completed');
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SimpleAudioTest] Error: $e');
        print('❌ [SimpleAudioTest] Error type: ${e.runtimeType}');
        print('❌ [SimpleAudioTest] Stack trace: ${StackTrace.current}');
      }
    }
  }
  
  static Future<void> testWithDifferentPaths() async {
    final paths = [
      'audio/email_sound.mp3',
      'assets/audio/email_sound.mp3',
      '/assets/audio/email_sound.mp3',
      './assets/audio/email_sound.mp3',
    ];
    
    for (final path in paths) {
      if (kDebugMode) {
        print('🧪 [SimpleAudioTest] Trying path: $path');
      }
      
      try {
        await _player.play(AssetSource(path));
        if (kDebugMode) {
          print('✅ [SimpleAudioTest] Success with path: $path');
        }
        await Future.delayed(const Duration(seconds: 1));
        await _player.stop();
        break;
      } catch (e) {
        if (kDebugMode) {
          print('❌ [SimpleAudioTest] Failed with path: $path - $e');
        }
      }
    }
  }
  
  static void dispose() {
    _player.dispose();
  }
}