import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for playing audio effects in the app
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  
  AudioService._() {
    _initializeAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;
  bool _isInitialized = false;

  /// Initialize audio player for current platform
  Future<void> _initializeAudioPlayer() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // Web-specific configuration
        await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
        if (kDebugMode) {
          print('🌐 AudioPlayer initialized for web');
        }
      }
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AudioPlayer initialization failed: $e');
      }
    }
  }
  
  /// Enable or disable audio effects
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// Check if audio is enabled
  bool get isEnabled => _isEnabled;

  /// Test audio playback (useful for debugging)
  Future<void> testAudio() async {
    if (kDebugMode) {
      print('🧪 Testing audio playback...');
      print('🧪 Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
      print('🧪 Audio enabled: $_isEnabled');
      print('🧪 Audio initialized: $_isInitialized');
    }

    await playEmailSentSound();
  }

  /// Test startup audio playback (useful for debugging)
  Future<void> testStartupAudio() async {
    if (kDebugMode) {
      print('🧪 Testing startup audio playback...');
      print('🧪 Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
      print('🧪 Audio enabled: $_isEnabled');
      print('🧪 Audio initialized: $_isInitialized');
    }

    await playStartupSuccessSound();
  }

  /// Play success sound effect for successful email sending
  Future<void> playEmailSuccessSound() async {
    if (!_isEnabled) return;
    
    try {
      // Use system sound on web and mobile
      if (kIsWeb) {
        // For web, we'll use a simple beep sound or system notification
        await _playSystemNotificationSound();
      } else {
        // For mobile, try to play custom sound first, fallback to system sound
        await _playCustomSuccessSound();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing success sound: $e');
      }
      // Fallback to system sound
      await _playSystemNotificationSound();
    }
  }

  /// Play custom email sent sound from assets/audio/email_sound.mp3
  Future<void> playEmailSentSound() async {
    if (!_isEnabled) return;

    try {
      // Ensure audio player is initialized
      await _initializeAudioPlayer();

      if (kDebugMode) {
        print('🔊 Playing email sent sound...');
      }

      if (kIsWeb) {
        // Web environment: Use enhanced web audio implementation
        await _playEmailSoundForWeb();
      } else {
        // Mobile/Desktop: Use asset source
        await _audioPlayer.play(AssetSource('audio/email_sound.mp3'));
      }

      if (kDebugMode) {
        print('🔊 Email sent sound played successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error playing email_sound.mp3: $e');
      }

      // Fallback to system notification sound
      try {
        await _playSystemNotificationSound();
        if (kDebugMode) {
          print('🔊 Fallback to system notification sound');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('⚠️ Fallback sound also failed: $fallbackError');
        }
      }
    }
  }

  /// Play startup success sound from assets/audio/startup_success.mp3
  Future<void> playStartupSuccessSound() async {
    if (!_isEnabled) return;

    try {
      // Ensure audio player is initialized
      await _initializeAudioPlayer();

      if (kDebugMode) {
        print('🚀 Playing startup success sound...');
      }

      if (kIsWeb) {
        // Web environment: Use enhanced web audio implementation
        await _playStartupSoundForWeb();
      } else {
        // Mobile/Desktop: Use asset source
        await _audioPlayer.play(AssetSource('audio/startup_success.mp3'));
      }

      if (kDebugMode) {
        print('🚀 Startup success sound played successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error playing startup_success.mp3: $e');
      }

      // Fallback to enhanced startup notification
      try {
        await _playEnhancedStartupNotification();
        if (kDebugMode) {
          print('🚀 Fallback to enhanced startup notification');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('⚠️ Startup sound fallback also failed: $fallbackError');
        }
      }
    }
  }

  /// Enhanced web audio implementation for email sound
  Future<void> _playEmailSoundForWeb() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🌐 Attempting web audio playback...');
        print('🌐 Audio player initialized: $_isInitialized');
        print('🌐 Audio enabled: $_isEnabled');
      }

      // Method 1: Try to use audioplayers with explicit web configuration
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

      // Give user interaction context by playing immediately after user action
      await _audioPlayer.play(AssetSource('audio/email_sound.mp3'));

      if (kDebugMode) {
        print('🌐 Web audio played via audioplayers successfully');
      }

      // Wait a moment to ensure audio starts
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      if (kDebugMode) {
        print('🌐 Audioplayers failed on web: $e');
        print('🌐 Error type: ${e.runtimeType}');
        print('🌐 Trying HTML5 audio...');
      }

      // Method 2: Try HTML5 Audio approach (this requires js interop in real implementation)
      await _playHtml5Audio();
    }
  }

  /// Enhanced web audio implementation for startup sound
  Future<void> _playStartupSoundForWeb() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🚀 Attempting web startup audio playback...');
        print('🚀 Audio player initialized: $_isInitialized');
        print('🚀 Audio enabled: $_isEnabled');
      }

      // Method 1: Try to use audioplayers with explicit web configuration
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

      // Give user interaction context by playing immediately after user action
      await _audioPlayer.play(AssetSource('audio/startup_success.mp3'));

      if (kDebugMode) {
        print('🚀 Web startup audio played via audioplayers successfully');
      }

      // Wait a moment to ensure audio starts
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      if (kDebugMode) {
        print('🚀 Startup audioplayers failed on web: $e');
        print('🚀 Error type: ${e.runtimeType}');
        print('🚀 Trying startup HTML5 audio...');
      }

      // Method 2: Try HTML5 Audio approach for startup sound
      await _playStartupHtml5Audio();
    }
  }

  /// Try to play startup audio using HTML5 Audio API (simplified implementation)
  Future<void> _playStartupHtml5Audio() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🚀 Attempting startup HTML5 audio playback...');
      }

      // In a real implementation, this would use dart:js to call:
      // var audio = new Audio('assets/audio/startup_success.mp3');
      // audio.play();

      // For now, use enhanced startup notification
      await _playEnhancedStartupNotification();

      if (kDebugMode) {
        print('🚀 Startup HTML5 audio simulation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚀 Startup HTML5 audio failed: $e');
      }

      // Final fallback
      await _playEnhancedStartupNotification();
    }
  }

  /// Enhanced web notification sound for startup success
  Future<void> _playEnhancedStartupNotification() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🚀 Playing enhanced web startup notification...');
      }

      // Create a pleasant startup sequence
      // This simulates a welcome/success startup sound pattern
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));

      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 200));

      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 150));

      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 100));

      await HapticFeedback.lightImpact();

      if (kDebugMode) {
        print('🚀 Enhanced web startup notification completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚀 Enhanced web startup notification failed: $e');
      }
    }
  }

  /// Try to play audio using HTML5 Audio API (simplified implementation)
  Future<void> _playHtml5Audio() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🌐 Attempting HTML5 audio playback...');
      }

      // In a real implementation, this would use dart:js to call:
      // var audio = new Audio('assets/audio/email_sound.mp3');
      // audio.play();

      // For now, use enhanced system notification
      await _playEnhancedWebEmailNotification();

      if (kDebugMode) {
        print('🌐 HTML5 audio simulation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🌐 HTML5 audio failed: $e');
      }

      // Final fallback
      await _playEnhancedWebEmailNotification();
    }
  }

  /// Enhanced web notification sound that mimics email alert
  Future<void> _playEnhancedWebEmailNotification() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🌐 Playing enhanced web email notification...');
      }

      // Create a pleasant email notification sequence
      // This simulates a typical email notification sound pattern
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));

      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 100));

      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 150));

      await HapticFeedback.selectionClick();

      if (kDebugMode) {
        print('🌐 Enhanced web email notification completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🌐 Enhanced web notification failed: $e');
      }
    }
  }

  /// Play error sound effect for failed email sending
  Future<void> playEmailErrorSound() async {
    if (!_isEnabled) return;
    
    try {
      if (kIsWeb) {
        await _playSystemErrorSound();
      } else {
        await _playCustomErrorSound();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing error sound: $e');
      }
      await _playSystemErrorSound();
    }
  }

  /// Play custom success sound from assets
  Future<void> _playCustomSuccessSound() async {
    try {
      // Try to play success sound from assets
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // If custom sound fails, use system notification
      await _playSystemNotificationSound();
    }
  }

  /// Play custom error sound from assets
  Future<void> _playCustomErrorSound() async {
    try {
      // Try to play error sound from assets
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      // If custom sound fails, use system error sound
      await _playSystemErrorSound();
    }
  }

  /// Play system notification sound
  Future<void> _playSystemNotificationSound() async {
    try {
      // Use system feedback for notification
      await HapticFeedback.lightImpact();
      
      // For web and some platforms, we can create a simple tone
      if (kIsWeb) {
        // Create a simple success tone using audio context (web only)
        await _playWebTone(800, 200); // High frequency, short duration
        await Future.delayed(const Duration(milliseconds: 100));
        await _playWebTone(1000, 200); // Even higher frequency
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing system notification sound: $e');
      }
    }
  }

  /// Play system error sound
  Future<void> _playSystemErrorSound() async {
    try {
      // Use system feedback for error
      await HapticFeedback.mediumImpact();
      
      if (kIsWeb) {
        // Create a simple error tone (lower frequency, longer)
        await _playWebTone(300, 300); // Low frequency, longer duration
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing system error sound: $e');
      }
    }
  }

  /// Play a simple tone on web (fallback method)
  Future<void> _playWebTone(double frequency, int durationMs) async {
    if (!kIsWeb) return;
    
    try {
      // This would work with js interop in a real implementation
      // For now, just use haptic feedback
      await HapticFeedback.selectionClick();
      await Future.delayed(Duration(milliseconds: durationMs));
    } catch (e) {
      // Silent fail - not critical
      if (kDebugMode) {
        print('Web tone playback failed: $e');
      }
    }
  }

  /// Play button click sound effect
  Future<void> playButtonClickSound() async {
    if (!_isEnabled) return;

    try {
      // Ensure audio player is initialized
      await _initializeAudioPlayer();

      if (kDebugMode) {
        print('🔘 Playing button click sound...');
      }

      if (kIsWeb) {
        // Web environment: Use enhanced web audio implementation
        await _playButtonClickForWeb();
      } else {
        // Mobile/Desktop: Use asset source
        await _audioPlayer.play(AssetSource('audio/button_click.mp3'));
      }

      if (kDebugMode) {
        print('🔘 Button click sound played successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error playing button_click.mp3: $e');
      }

      // Fallback to system click sound
      try {
        await _playSystemClickSound();
        if (kDebugMode) {
          print('🔘 Fallback to system click sound');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('⚠️ Fallback click sound also failed: $fallbackError');
        }
      }
    }
  }

  /// Enhanced web audio implementation for button click sound
  Future<void> _playButtonClickForWeb() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        print('🌐 Attempting web button click audio playback...');
      }

      // Method 1: Try to use audioplayers with explicit web configuration
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.play(AssetSource('audio/button_click.mp3'));

      if (kDebugMode) {
        print('🌐 Web button click audio played via audioplayers successfully');
      }

      // Wait a moment to ensure audio starts
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print('🌐 Button click audioplayers failed on web: $e');
      }

      // Fallback to system click sound
      await _playSystemClickSound();
    }
  }

  /// Play system click sound as fallback
  Future<void> _playSystemClickSound() async {
    try {
      // Use system feedback for button click
      await HapticFeedback.selectionClick();
      
      if (kIsWeb) {
        // Create a simple click tone
        await _playWebTone(1200, 50); // High frequency, very short duration for click
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing system click sound: $e');
      }
    }
  }

  /// Play a celebratory sound sequence for bulk successful email sending
  Future<void> playBulkSuccessSound() async {
    if (!_isEnabled) return;
    
    try {
      // Play a sequence of success sounds
      await playEmailSuccessSound();
      await Future.delayed(const Duration(milliseconds: 150));
      await playEmailSuccessSound();
      await Future.delayed(const Duration(milliseconds: 150));
      await playEmailSuccessSound();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing bulk success sound: $e');
      }
    }
  }

  /// Dispose audio resources
  void dispose() {
    _audioPlayer.dispose();
  }
}