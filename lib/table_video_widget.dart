import 'dart:async';

import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:easy_tv_live/util/env_util.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:easy_tv_live/util/m3u_util.dart';
import 'package:easy_tv_live/widget/date_position_widget.dart';
import 'package:easy_tv_live/widget/video_hold_bg.dart';
import 'package:easy_tv_live/widget/volume_brightness_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'generated/l10n.dart';

class TableVideoWidget extends StatefulWidget {
  final VideoController? controller;
  /// VLC（libVLC）内核时传入，与 [controller] 二选一。
  final vlc.Player? vlcPlayer;
  final bool useVlc;
  final GestureTapCallback? changeChannelSources;
  final String? toastString;
  final bool isLandscape;
  final bool isBuffering;
  final bool isPlaying;
  final double aspectRatio;
  final bool drawerIsOpen;
  final GestureTapCallback onChangeSubSource;
  final GestureTapCallback onPreviousChannel;
  final GestureTapCallback onNextChannel;
  final GestureTapCallback onSwitchSource;
  const TableVideoWidget({
    super.key,
    this.controller,
    this.vlcPlayer,
    this.useVlc = false,
    required this.isBuffering,
    required this.isPlaying,
    required this.aspectRatio,
    required this.drawerIsOpen,
    required this.onChangeSubSource,
    required this.onPreviousChannel,
    required this.onNextChannel,
    required this.onSwitchSource,
    this.toastString,
    this.changeChannelSources,
    this.isLandscape = true,
  });

  @override
  State<TableVideoWidget> createState() => _TableVideoWidgetState();
}

class _TableVideoWidgetState extends State<TableVideoWidget>
    with WindowListener {
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

  bool get _hasVideo =>
      (widget.useVlc && widget.vlcPlayer != null) ||
      (!widget.useVlc && widget.controller != null);

  bool _isShowMenuBar = true;

  bool _isShowOpView = true;

  // 控制中间按钮的显示隐藏
  bool _isShowCenterButtons = false;

  // 鼠标停留自动隐藏的计时器
  Timer? _hideTimer;
  @override
  void initState() {
    super.initState();
    if (!EnvUtil.isMobile) windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (!EnvUtil.isMobile) windowManager.removeListener(this);
    _hideTimer?.cancel();
    super.dispose();
  }

  // @override
  // void onWindowEnterFullScreen() {
  //   super.onWindowEnterFullScreen();
  //   windowManager.setTitleBarStyle(TitleBarStyle.normal, windowButtonVisibility: true);
  // }
  //
  // @override
  // void onWindowLeaveFullScreen() {
  //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
  // }

  @override
  void onWindowEnterFullScreen() {
    super.onWindowEnterFullScreen();
    if (!EnvUtil.isMobile) {
      windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (!EnvUtil.isMobile) {
      windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: true,
      );
    }
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    // 移除宽高比限制，允许自由调整窗口大小
    // await windowManager.setAspectRatio(16/9);
    if (size.width < 600) {
      if (!_isShowOpView) return;
      _isShowOpView = false;
      setState(() {});
    } else {
      if (_isShowOpView) return;
      _isShowOpView = true;
      setState(() {});
    }
  }

  _pushSettingPage(BuildContext context) async {
    _pause();
    await M3uUtil.openAddSource(context);
    final isChange = await M3uUtil.isChangeChannelLink();
    if (isChange) {
      widget.onChangeSubSource.call();
    } else {
      _play();
    }
  }

  _pushChannelDrawer(BuildContext context) {
    setState(() {
      _isShowMenuBar = false;
    });
    Scaffold.of(context).openDrawer();
  }

  _nextChannel() {
    setState(() {
      _isShowMenuBar = false;
      _isShowCenterButtons = false;
    });
    LogUtil.v('下一个：：：：');
    widget.onNextChannel();
  }

  _previousChannel() {
    setState(() {
      _isShowMenuBar = false;
      _isShowCenterButtons = false;
    });
    widget.onPreviousChannel();
  }

  _toggleLine() {
    setState(() {
      _isShowMenuBar = false;
      _isShowCenterButtons = false;
    });
    LogUtil.v('切换源：：：：');
    widget.onSwitchSource();
  }

  // 重置自动隐藏计时器
  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isShowCenterButtons) {
        setState(() {
          _isShowCenterButtons = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isShowCenterButtons
          ? SystemMouseCursors.basic
          : SystemMouseCursors.none,
      onHover: (event) {
        // 鼠标在播放区域移动时显示按钮并重置计时器
        if (widget.isLandscape && !widget.drawerIsOpen) {
          if (!_isShowCenterButtons) {
            setState(() {
              _isShowCenterButtons = true;
            });
          }
          _resetHideTimer();
        }
      },
      onExit: (event) {
        // 鼠标离开播放区域时取消计时器并立即隐藏按钮
        _hideTimer?.cancel();
        if (_isShowCenterButtons) {
          setState(() {
            _isShowCenterButtons = false;
          });
        }
      },
      child: Stack(
        children: [
          InkWell(
            onTap: widget.isLandscape
                ? () {
                    _isShowMenuBar = !_isShowMenuBar;
                    setState(() {});
                  }
                : null,
            onDoubleTap: () {
              if (widget.isPlaying) {
                _pause();
              } else {
                _play();
              }
            },
            onHover: (bool isHover) {
              // if (isHover) {
              //   _timer?.cancel();
              //   windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
              //   _timer = Timer(const Duration(seconds: 8), () {
              //     windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
              //   });
              // }
            },
            child: Container(
              alignment: Alignment.center,
              color: Colors.black,
              child: _hasVideo
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: widget.useVlc
                              ? vlc.Video(
                                  player: widget.vlcPlayer!,
                                  fit: BoxFit.cover,
                                  showControls: false,
                                )
                              : Video(
                                  controller: widget.controller!,
                                  fit: BoxFit.cover,
                                  controls: NoVideoControls,
                                ),
                        ),
                        if (!widget.isPlaying && !widget.drawerIsOpen)
                          GestureDetector(
                            onTap: () {
                              _play();
                            },
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        if (widget.isBuffering && !widget.drawerIsOpen)
                          const SpinKitSpinningLines(color: Colors.white),
                      ],
                    )
                  : VideoHoldBg(
                      toastString: widget.drawerIsOpen
                          ? ''
                          : widget.toastString,
                    ),
            ),
          ),
          if (_isShowOpView) ...[
            if (widget.drawerIsOpen ||
                (!widget.drawerIsOpen && _isShowMenuBar && widget.isLandscape))
              DatePositionWidget(
                player: widget.useVlc ? null : widget.controller?.player,
              ),
            // 取消左侧的两个快捷操作按钮（进入设置和打开频道列表）
            // if (widget.isLandscape)
            //   Builder(
            //     builder: (BuildContext context) {
            //       return Row(
            //         children: [
            //           Material(
            //             color: Colors.transparent,
            //             child: SizedBox(
            //               width: 10,
            //               height: MediaQuery.of(context).size.height,
            //               child: Column(
            //                 children: [
            //                   Expanded(
            //                     child: InkWell(
            //                       onTap: () => _pushSettingPage(context),
            //                       child: Tooltip(
            //                         message: '进入设置',
            //                         child: SizedBox(width: 10, height: MediaQuery.of(context).size.height),
            //                       ),
            //                     ),
            //                   ),
            //                   Expanded(
            //                     child: InkWell(
            //                       onTap: () => _pushChannelDrawer(context),
            //                       child: Tooltip(
            //                         message: '打开频道列表',
            //                         child: SizedBox(width: 10, height: MediaQuery.of(context).size.height),
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           Expanded(child: const VolumeBrightnessWidget()),
            //         ],
            //       );
            //     },
            //   ),
            if (widget.isLandscape) const VolumeBrightnessWidget(),
            if (widget.isLandscape && !widget.drawerIsOpen)
              AnimatedPositioned(
                left: 0,
                right: 0,
                bottom: _isShowMenuBar || !widget.isPlaying ? 5 : -50,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        tooltip: '进入设置',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () async {
                          _pause();
                          await M3uUtil.openAddSource(context);
                          final isChange = await M3uUtil.isChangeChannelLink();
                          if (isChange) {
                            widget.onChangeSubSource.call();
                          } else {
                            _play();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: S.current.tipChannelList,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.list_alt, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isShowMenuBar = false;
                          });
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: S.current.tipChangeLine,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(
                          Icons.legend_toggle,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isShowMenuBar = false;
                          });
                          widget.changeChannelSources?.call();
                        },
                      ),
                      if (EnvUtil.isMobile) const SizedBox(width: 12),
                      if (EnvUtil.isMobile)
                        IconButton(
                          tooltip: S.current.portrait,
                          onPressed: () async {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                            ]);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.white),
                          ),
                          icon: const Icon(
                            Icons.screen_rotation,
                            color: Colors.white,
                          ),
                        ),
                      if (!EnvUtil.isMobile) const SizedBox(width: 12),
                      if (!EnvUtil.isMobile)
                        IconButton(
                          tooltip: S.current.fullScreen,
                          onPressed: () async {
                            final isFullScreen = await windowManager
                                .isFullScreen();
                            LogUtil.v('isFullScreen:::::$isFullScreen');
                            windowManager.setFullScreen(!isFullScreen);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.white),
                          ),
                          icon: FutureBuilder<bool>(
                            future: windowManager.isFullScreen(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Icon(
                                  snapshot.data!
                                      ? Icons.close_fullscreen
                                      : Icons.fit_screen_outlined,
                                  color: Colors.white,
                                );
                              } else {
                                return const Icon(
                                  Icons.fit_screen_outlined,
                                  color: Colors.white,
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!widget.isLandscape)
              Positioned(
                right: 15,
                bottom: 15,
                child: IconButton(
                  tooltip: S.current.landscape,
                  onPressed: () async {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    iconSize: 20,
                  ),
                  icon: const Icon(Icons.screen_rotation, color: Colors.white),
                ),
              ),
            // 底部中间的三个圆形按钮 - 鼠标移动时显示
            if (widget.isLandscape &&
                !widget.drawerIsOpen &&
                _isShowCenterButtons)
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 上一频道按钮
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _previousChannel,
                            tooltip: '上一频道',
                          ),
                        ),
                        const SizedBox(width: 30),
                        // 切换线路按钮
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.sync,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _toggleLine,
                            tooltip: '切换线路',
                          ),
                        ),
                        const SizedBox(width: 30),
                        // 下一频道按钮
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _nextChannel,
                            tooltip: '下一频道',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
