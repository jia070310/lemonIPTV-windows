import 'dart:io' show Platform;

/// 桌面端是否可使用 dart_vlc（libVLC）。Android / iOS / macOS 当前包未作为目标平台。
bool get isVlcPlaybackSupported =>
    Platform.isWindows || Platform.isLinux;

enum PlaybackEngine {
  mpv,
  vlc,
}

PlaybackEngine playbackEngineFromStorage(String? s) =>
    s == 'vlc' ? PlaybackEngine.vlc : PlaybackEngine.mpv;

String playbackEngineToStorage(PlaybackEngine e) => e.name;

/// 根据错误文案尝试自动切换到另一内核（解码/硬件相关）。
bool shouldAutoSwitchPlaybackEngine(String error) {
  final e = error.toLowerCase();
  return e.contains('decod') ||
      e.contains('codec') ||
      e.contains('corrupt') ||
      e.contains('hardware') ||
      e.contains('lavc') ||
      e.contains('vld') ||
      e.contains('gpu') ||
      e.contains('dxva') ||
      e.contains('d3d11');
}
