import 'dart:io' show Platform;

import 'package:dart_vlc/dart_vlc.dart' as vlc;

/// Windows / Linux 下初始化 libVLC；其它平台为 no-op。
void initVlcIfDesktop() {
  if (Platform.isWindows || Platform.isLinux) {
    vlc.DartVLC.initialize();
  }
}
