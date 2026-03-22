import 'package:media_kit/media_kit.dart';
import 'package:sp_util/sp_util.dart';

/// 4K / 直播场景下 demuxer 缓冲上限（字节）。默认 media_kit 为 32MB，偏小易导致高码率卡顿。
const int kLiveDemuxerBufferBytes = 96 * 1024 * 1024;

const String _kPreferSoftwareDecode = 'preferSoftwareDecode';

/// 是否在设置中开启「优先软解」（缓解部分显卡硬解花屏，CPU 占用更高）。
bool get preferSoftwareDecode =>
    SpUtil.getBool(_kPreferSoftwareDecode, defValue: false)!;

Future<void> setPreferSoftwareDecode(bool value) async {
  await SpUtil.putBool(_kPreferSoftwareDecode, value);
}

/// 在 libmpv 初始化或每次 [open] 后调用，优化直播卡顿；花屏时需区分码流与硬解（见 README 级注释无，此处仅调参）。
Future<void> applyMpvLiveTuning(Player player) async {
  final plat = player.platform;
  if (plat == null) return;
  final dynamic p = plat;
  Future<void> safe(String name, String value) async {
    try {
      await p.setProperty(name, value);
    } catch (_) {}
  }

  if (preferSoftwareDecode) {
    await safe('hwdec', 'no');
  } else {
    await safe('hwdec', 'auto-safe');
  }
  await safe('vd-lavc-dr', 'no');
  await safe('video-sync', 'audio');
  await safe('network-timeout', '60');
  await safe('cache-secs', '120');
  await safe('demuxer-readahead-secs', '30');
}

/// 读取 mpv [cache-speed]（字节/秒），作为当前拉流吞吐的近似值；不可用时返回 null。
Future<double?> readMpvCacheSpeedBps(Player? player) async {
  if (player == null) return null;
  final plat = player.platform;
  if (plat == null) return null;
  try {
    final dynamic p = plat;
    final String s = await p.getProperty('cache-speed');
    if (s.isEmpty) return null;
    return double.tryParse(s.trim());
  } catch (_) {
    return null;
  }
}

String formatBytesPerSecond(double? bps) {
  if (bps == null || bps.isNaN || bps < 0) return '—';
  if (bps < 512) return '${bps.toStringAsFixed(0)} B/s';
  if (bps < 512 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
  return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
}
