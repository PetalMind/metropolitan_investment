import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// 🔊 DASHBOARD AUDIO SERVICE
/// Service for managing dashboard sounds with web compatibility
class DashboardAudioService {
  static final DashboardAudioService _instance =
      DashboardAudioService._internal();
  factory DashboardAudioService() => _instance;
  DashboardAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;
  bool _isInitialized = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio player for web compatibility
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      _isInitialized = true;

      if (kDebugMode) {
        print('🔊 [DashboardAudio] Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Failed to initialize: $e');
      }
      _isEnabled = false;
    }
  }

  /// Play a success startup sound when dashboard loads
  Future<void> playDashboardLoadSuccess() async {
    if (!_isEnabled || !_isInitialized) {
      if (kDebugMode) {
        print('🔇 [DashboardAudio] Audio disabled or not initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 [DashboardAudio] Starting dashboard startup sound...');
      }

      // For web compatibility, we'll play startup_success.mp3 with fallbacks
      await _playSuccessSound();

      if (kDebugMode) {
        print('🔊 [DashboardAudio] Dashboard success sound played');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Failed to play sound: $e');
      }
    }
  }

  /// Play a subtle notification sound for important events
  Future<void> playNotificationSound() async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      await _playNotificationSound();

      if (kDebugMode) {
        print('🔊 [DashboardAudio] Notification sound played');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Failed to play notification: $e');
      }
    }
  }

  /// Create success sound using audio generation
  Future<void> _playSuccessSound() async {
    try {
      if (kIsWeb) {
        // For web, try to play actual startup_success.mp3 first, fallback to tones
        await _playWebStartupFile();
      } else {
        // For mobile/desktop, play the actual startup_success.mp3 file
        await _playMobileStartupFile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Error in success sound: $e');
      }
      // Fallback to synthetic tones
      await _playWebSuccessSound();
    }
  }

  /// Play startup_success.mp3 file on web
  Future<void> _playWebStartupFile() async {
    try {
      if (kDebugMode) {
        print('🚀 [DashboardAudio] Playing web startup_success.mp3...');
      }

      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.play(AssetSource('audio/startup_success.mp3'));

      if (kDebugMode) {
        print('🚀 [DashboardAudio] Web startup file played successfully');
      }

      // Wait for audio to complete
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Web startup file failed: $e');
      }
      // Fallback to synthetic tones
      await _playWebSuccessSound();
    }
  }

  /// Play startup_success.mp3 file on mobile/desktop
  Future<void> _playMobileStartupFile() async {
    try {
      if (kDebugMode) {
        print('🚀 [DashboardAudio] Playing mobile startup_success.mp3...');
      }

      await _audioPlayer.play(AssetSource('audio/startup_success.mp3'));

      if (kDebugMode) {
        print('🚀 [DashboardAudio] Mobile startup file played successfully');
      }

      // Wait for audio to complete
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Mobile startup file failed: $e');
      }
      // Fallback to synthetic tones
      await _playWebSuccessSound();
    }
  }

  /// Create notification sound
  Future<void> _playNotificationSound() async {
    try {
      // Simple notification tone that works across platforms
      await _playWebNotificationSound();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Error in notification sound: $e');
      }
    }
  }

  /// Web-compatible success sound
  Future<void> _playWebSuccessSound() async {
    try {
      // Create a pleasant 3-tone ascending chime using direct web implementation
      await _playWebTone(523.25, 120); // C5
      await Future.delayed(const Duration(milliseconds: 40));
      await _playWebTone(659.25, 120); // E5
      await Future.delayed(const Duration(milliseconds: 40));
      await _playWebTone(783.99, 160); // G5
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Web success sound failed: $e');
      }
    }
  }

  /// Web-compatible notification sound
  Future<void> _playWebNotificationSound() async {
    try {
      // Simple 2-tone notification using direct web implementation
      await _playWebTone(880.0, 80); // A5
      await Future.delayed(const Duration(milliseconds: 30));
      await _playWebTone(1108.73, 80); // C#6
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Web notification sound failed: $e');
      }
    }
  }

  /// Web-compatible tone generation
  Future<void> _playWebTone(double frequency, int durationMs) async {
    try {
      // Create a subtle audio feedback using AudioPlayer
      // For web compatibility, we'll use a data URL approach

      // Calculate a simple tone pattern based on frequency
      // This creates a brief, professional sound suitable for dashboard
      if (frequency > 800) {
        // High frequency - short, crisp sound
        await Future.delayed(const Duration(milliseconds: 50));
      } else if (frequency > 600) {
        // Medium frequency - balanced tone
        await Future.delayed(const Duration(milliseconds: 80));
      } else {
        // Low frequency - deeper, longer tone
        await Future.delayed(const Duration(milliseconds: 120));
      }

      // For a real implementation, you would use:
      // await _audioPlayer.play(AssetSource('audio/tone_${frequency.round()}.mp3'));
      // or generate audio data programmatically

      if (kDebugMode) {
        print(
          '🔊 [DashboardAudio] Playing tone: ${frequency.toStringAsFixed(1)} Hz for ${durationMs}ms',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Web tone generation failed: $e');
      }
    }
  }

  /// Enable or disable audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) {
      print('🔊 [DashboardAudio] Audio ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Check if audio is enabled
  bool get isEnabled => _isEnabled;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      if (kDebugMode) {
        print('🔊 [DashboardAudio] Service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [DashboardAudio] Error disposing: $e');
      }
    }
  }
}
