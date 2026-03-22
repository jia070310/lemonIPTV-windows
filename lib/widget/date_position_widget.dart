import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../util/date_util.dart';
import '../util/mpv_live_helper.dart';

/// 右上角日期时间；可选传入 [player] 时显示 libmpv 报告的缓存读取速率（近似实时网速）。
class DatePositionWidget extends StatefulWidget {
  const DatePositionWidget({super.key, this.player});

  final Player? player;

  @override
  State<DatePositionWidget> createState() => _DatePositionWidgetState();
}

class _DatePositionWidgetState extends State<DatePositionWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  double? _cacheSpeedBps;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant DatePositionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _cacheSpeedBps = null;
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final newNow = DateTime.now();
    final p = widget.player;
    final v = p != null ? await readMpvCacheSpeedBps(p) : null;
    if (!mounted) return;
    setState(() {
      _now = newNow;
      _cacheSpeedBps = v;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: IgnorePointer(
        child: Card(
          color: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateUtil.formatDate(_now, format: 'HH:mm'),
                  style: const TextStyle(fontSize: 50),
                ),
                Text(
                  DateUtil.formatDate(_now, format: 'yyyy/MM/dd'),
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  DateUtil.getWeekday(_now, languageCode: 'zh'),
                  style: const TextStyle(fontSize: 20),
                ),
                if (widget.player != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '网速 ${formatBytesPerSecond(_cacheSpeedBps)}',
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
