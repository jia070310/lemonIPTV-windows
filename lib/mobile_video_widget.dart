import 'dart:math';

import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:easy_tv_live/router_keys.dart';
import 'package:easy_tv_live/setting/subscribe_page.dart';
import 'package:easy_tv_live/table_video_widget.dart';
import 'package:easy_tv_live/util/m3u_util.dart';
import 'package:easy_tv_live/widget/empty_page.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/l10n.dart';

class MobileVideoWidget extends StatefulWidget {
  final VideoController? controller;
  final vlc.Player? vlcPlayer;
  /// 竖屏分支在桌面选 VLC 时可为 true。
  final bool useVlc;
  final GestureTapCallback? changeChannelSources;
  final String? toastString;
  final bool isLandscape;
  final Widget drawChild;
  final bool isBuffering;
  final bool isPlaying;
  final double aspectRatio;
  final GestureTapCallback onChangeSubSource;
  final GestureTapCallback onPreviousChannel;
  final GestureTapCallback onNextChannel;
  final GestureTapCallback onSwitchSource;

  const MobileVideoWidget({
    super.key,
    this.controller,
    this.vlcPlayer,
    this.useVlc = false,
    required this.drawChild,
    required this.isBuffering,
    required this.isPlaying,
    required this.aspectRatio,
    // 数据源改变
    required this.onChangeSubSource,
    required this.onPreviousChannel,
    required this.onNextChannel,
    required this.onSwitchSource,
    this.toastString,
    // 线路切换
    this.changeChannelSources,
    this.isLandscape = true,
  });

  @override
  State<MobileVideoWidget> createState() => _MobileVideoWidgetState();
}

class _MobileVideoWidgetState extends State<MobileVideoWidget> {
  void _pause() {
    if (widget.useVlc) {
      widget.vlcPlayer?.pause();
    } else {
      widget.controller?.player.pause();
    }
  }

  void _play() {
    if (widget.useVlc) {
      widget.vlcPlayer?.play();
    } else {
      widget.controller?.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(S.current.appName),
        leading: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () async {
            _pause();
            final res = await Navigator.of(context).pushNamed(RouterKeys.settingQrScan);
            if (res != null && res != '') {
              _pause();
              final uri = Uri.parse(res.toString());
              if (uri.host.contains('9928')) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) {
                    return const SubScribePage(isTV: false);
                  },
                ),
              );
              final isChange = await M3uUtil.isChangeChannelLink();
              if (isChange) {
                widget.onChangeSubSource.call();
              } else {
                _play();
              }
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // if (!EnvUtil.isMobile) {
              //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
              // }
              if (widget.isPlaying) {
                _pause();
              }
              await Navigator.of(context).pushNamed(RouterKeys.subScribe);
              final isChange = await M3uUtil.isChangeChannelLink();
              if (isChange) {
                widget.onChangeSubSource.call();
              } else {
                _play();
              }
              // if (!EnvUtil.isMobile) {
              //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
              // }
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () async {
              // if (!EnvUtil.isMobile) {
              //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
              // }
              _pause();
              await Navigator.of(context).pushNamed(RouterKeys.setting);
              _play();
              // if (!EnvUtil.isMobile) {
              //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
              // }
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: max(widget.aspectRatio, 16 / 9),
            child: TableVideoWidget(
              controller: widget.useVlc ? null : widget.controller,
              vlcPlayer: widget.vlcPlayer,
              useVlc: widget.useVlc,
              toastString: widget.toastString,
              isLandscape: false,
              aspectRatio: max(widget.aspectRatio, 16 / 9),
              isBuffering: widget.isBuffering,
              isPlaying: widget.isPlaying,
              changeChannelSources: widget.changeChannelSources,
              onChangeSubSource: widget.onChangeSubSource,
              drawerIsOpen: false,
              onPreviousChannel: widget.onPreviousChannel,
              onNextChannel: widget.onNextChannel,
              onSwitchSource: widget.onSwitchSource,
            ),
          ),
          Flexible(child: widget.toastString == 'UNKNOWN' ? EmptyPage(onRefresh: widget.onChangeSubSource) : widget.drawChild),
        ],
      ),
    );
  }
}
