import 'package:flutter/foundation.dart';

/// Resolve asset path depending on platform.
///
/// - On mobile (Android/iOS) we ensure the path is prefixed with `assets/`.
/// - On web we strip a leading `assets/` because the web asset server may serve
///   files without that prefix in some setups.
String resolveAssetPath(String path) {
  final p = path.trim();

  // Leave package and network paths unchanged
  if (p.startsWith('package:') || p.startsWith('http://') || p.startsWith('https://') || p.startsWith('/')) {
    return p;
  }

  if (kIsWeb) {
    if (p.startsWith('assets/')) return p.substring('assets/'.length);
    return p;
  }

  // Mobile and other platforms: ensure assets/ prefix
  if (p.startsWith('assets/')) return p;
  return 'assets/$p';
}
