/// Debug configuration for development/production builds
class DebugConfig {
  // Disable verbose logging for production builds
  static const bool enableVerboseLogging = false;
  
  // Disable cache debugging
  static const bool enableCacheDebug = false;
  
  // Disable Firebase Functions detailed logging  
  static const bool enableFirebaseFunctionsLogging = false;
  
  // Simplified print function that respects config
  static void debugPrint(String message) {
    if (enableVerboseLogging) {
      print(message);
    }
  }
  
  static void functionsLog(String message) {
    if (enableFirebaseFunctionsLogging) {
      print(message);
    }
  }
}
