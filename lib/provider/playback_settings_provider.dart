import 'package:flutter/foundation.dart';
import 'package:sp_util/sp_util.dart';

import '../util/playback_engine.dart';

/// 播放内核（mpv / VLC）与持久化。
class PlaybackSettingsProvider extends ChangeNotifier {
  static const _kEngine = 'playback_engine';

  PlaybackEngine _engine = PlaybackEngine.mpv;

  PlaybackSettingsProvider() {
    _engine = playbackEngineFromStorage(SpUtil.getString(_kEngine, defValue: 'mpv'));
  }

  PlaybackEngine get engine => _engine;

  Future<void> setEngine(PlaybackEngine e) async {
    if (_engine == e) return;
    await SpUtil.putString(_kEngine, playbackEngineToStorage(e));
    _engine = e;
    notifyListeners();
  }
}
