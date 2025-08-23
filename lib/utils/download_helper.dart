// Conditional re-exports to pick platform-specific implementations
export 'download_helper_stub.dart'
  if (dart.library.html) 'download_helper_web.dart'
  if (dart.library.io) 'download_helper_io.dart';
