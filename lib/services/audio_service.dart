import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for playing audio effects in the app
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  
  AudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;
  
  /// Enable or disable audio effects
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// Check if audio is enabled
  bool get isEnabled => _isEnabled;

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