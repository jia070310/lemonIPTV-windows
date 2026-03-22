import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:easy_tv_live/provider/download_provider.dart';
import 'package:easy_tv_live/provider/playback_settings_provider.dart';
import 'package:easy_tv_live/provider/theme_provider.dart';
import 'package:easy_tv_live/util/latency_checker_util.dart';
import 'package:easy_tv_live/widget/focus_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'channel_drawer_page.dart';
import 'entity/play_channel_list_model.dart';
import 'generated/l10n.dart';
import 'mobile_video_widget.dart';
import 'table_video_widget.dart';
import 'tv/tv_page.dart';
import 'util/check_version_util.dart';
import 'util/env_util.dart';
import 'util/epg_util.dart';
import 'util/log_util.dart';
import 'util/mpv_live_helper.dart';
import 'util/m3u_util.dart';
import 'util/playback_engine.dart';
import 'widget/empty_page.dart';

class LiveHomePage extends StatefulWidget {
  const LiveHomePage({super.key});

  @override
  State<LiveHomePage> createState() => _LiveHomePageState();
}

class _LiveHomePageState extends State<LiveHomePage> {
  String toastString = S.current.loading;

  PlayChannelListModel? _channelListModel;

  Channel? _currentChannel;

  int _sourceIndex = 0;

  Player? _player;
  VideoController? _playerController;

  vlc.Player? _vlcPlayer;
  final List<StreamSubscription<dynamic>> _mpvSubscriptions = [];
  final List<StreamSubscription<dynamic>> _vlcSubscriptions = [];

  PlaybackSettingsProvider? _playbackSettings;
  PlaybackEngine _effectiveEngine = PlaybackEngine.mpv;
  bool _autoEngineSwitchConsumed = false;

  bool isBuffering = false;

  bool isPlaying = false;
  double aspectRatio = 16/9;

  bool _drawerIsOpen = false;

  int _channelSerialNum = 1;

  bool get _useVlcPlayback =>
      !EnvUtil.isTV() &&
      isVlcPlaybackSupported &&
      _effectiveEngine == PlaybackEngine.vlc;

  @override
  void initState() {
    super.initState();
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorColor = Colors.black
      ..textColor = Colors.black
      ..backgroundColor = Colors.white70;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _playbackSettings = context.read<PlaybackSettingsProvider>();
      _effectiveEngine = _playbackSettings!.engine;
      _playbackSettings!.addListener(_onPlaybackSettingsChanged);
      await _bootstrapPlayback();
      Future.delayed(Duration.zero, _loadData);
    });
  }

  void _onPlaybackSettingsChanged() {
    if (!mounted || _playbackSettings == null) return;
    final next = _playbackSettings!.engine;
    if (next == _effectiveEngine) return;
    _effectiveEngine = next;
    unawaited(_switchPlaybackEngine());
  }

  Future<void> _switchPlaybackEngine() async {
    await _disposeMpvInternal();
    _disposeVlcInternal();
    await _bootstrapPlayback();
    if (_currentChannel != null) {
      _playVideo('切换播放内核');
    }
  }

  Future<void> _bootstrapPlayback() async {
    if (EnvUtil.isTV() || !_useVlcPlayback) {
      await _createMpvPlayerIfNeeded();
    } else {
      await _createVlcPlayerIfNeeded();
    }
  }

  Future<void> _disposeMpvInternal() async {
    for (final s in _mpvSubscriptions) {
      s.cancel();
    }
    _mpvSubscriptions.clear();
    _playerController = null;
    await _player?.dispose();
    _player = null;
  }

  void _disposeVlcInternal() {
    for (final s in _vlcSubscriptions) {
      s.cancel();
    }
    _vlcSubscriptions.clear();
    _vlcPlayer?.dispose();
    _vlcPlayer = null;
  }

  Future<void> _createMpvPlayerIfNeeded() async {
    if (_player != null) return;
    _disposeVlcInternal();
    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: kLiveDemuxerBufferBytes,
        ready: () {
          final p = _player;
          if (p != null) {
            Future.microtask(() => applyMpvLiveTuning(p));
          }
        },
      ),
    );
    _playerController = VideoController(_player!);
    _mpvSubscriptions.add(_player!.stream.buffering.listen((event) {
      if (mounted && isBuffering != event) {
        setState(() {
          isBuffering = event;
        });
      }
    }));
    _mpvSubscriptions.add(_player!.stream.playing.listen((event) {
      if (mounted && isPlaying != event) {
        setState(() {
          isPlaying = event;
        });
      }
    }));
    _mpvSubscriptions.add(_player!.stream.error.listen((event) {
      LogUtil.v('播放出错(stream):::::$event');
      if (mounted) _onPlaybackError(event);
    }));
    _mpvSubscriptions.add(_player!.stream.completed.listen((event) {
      if (event && mounted) {
        _handleLineOrPlayError();
      }
    }));
    _mpvSubscriptions.add(_player!.stream.width.listen((_) => _updateAspectRatioMpv()));
    _mpvSubscriptions.add(_player!.stream.height.listen((_) => _updateAspectRatioMpv()));
  }

  Future<void> _createVlcPlayerIfNeeded() async {
    if (_vlcPlayer != null) return;
    await _disposeMpvInternal();
    final args = <String>[];
    if (preferSoftwareDecode) {
      args.add('--avcodec-hw=none');
    }
    _vlcPlayer = vlc.Player(
      id: 88401,
      videoDimensions: const vlc.VideoDimensions(1920, 1080),
      commandlineArguments: args,
    );
    _vlcSubscriptions.add(_vlcPlayer!.playbackStream.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state.isPlaying;
      });
    }));
    _vlcSubscriptions.add(_vlcPlayer!.bufferingProgressStream.listen((p) {
      if (!mounted) return;
      final b = p <= 1.0 ? p < 0.99 : p < 99.0;
      if (isBuffering != b) {
        setState(() {
          isBuffering = b;
        });
      }
    }));
    _vlcSubscriptions.add(_vlcPlayer!.errorStream.listen((e) {
      if (e.isEmpty || !mounted) return;
      LogUtil.v('VLC 错误:::::$e');
      _onPlaybackError(e);
    }));
    _vlcSubscriptions.add(_vlcPlayer!.videoDimensionsStream.listen((d) {
      if (!mounted) return;
      if (d.width > 0 && d.height > 0) {
        final r = d.width / d.height;
        if (aspectRatio != r) {
          setState(() {
            aspectRatio = r;
          });
        }
      }
    }));
  }

  void _updateAspectRatioMpv() {
    if (_player == null) return;
    final width = _player!.state.width ?? 0;
    final height = _player!.state.height ?? 0;
    if (width > 0 && height > 0) {
      final newRatio = width / height;
      if (mounted && aspectRatio != newRatio) {
        setState(() {
          aspectRatio = newRatio;
        });
      }
    }
  }

  void _onPlaybackError(String event) {
    if (_tryAutoSwitchEngine(event)) return;
    _handleLineOrPlayError();
  }

  bool _tryAutoSwitchEngine(String error) {
    if (_autoEngineSwitchConsumed) return false;
    if (!shouldAutoSwitchPlaybackEngine(error)) return false;
    if (EnvUtil.isTV() || !isVlcPlaybackSupported) return false;
    final other =
        _useVlcPlayback ? PlaybackEngine.mpv : PlaybackEngine.vlc;
    _autoEngineSwitchConsumed = true;
    EasyLoading.showToast(
      other == PlaybackEngine.vlc ? '解码异常，正在切换到 VLC 内核…' : '解码异常，正在切换到 mpv 内核…',
      toastPosition: EasyLoadingToastPosition.top,
    );
    _playbackSettings?.setEngine(other);
    return true;
  }

  void _handleLineOrPlayError() async {
    _sourceIndex += 1;
    if (_sourceIndex > _currentChannel!.urls!.length - 1) {
      _sourceIndex = _currentChannel!.urls!.length - 1;
      setState(() {
        toastString = S.current.playError(_currentChannel!.title ?? '');
      });
    } else {
      setState(() {
        toastString = S.current.switchLine(_sourceIndex + 1);
      });
      await Future.delayed(const Duration(seconds: 2));
      _playVideo('错误拦截后再次进入，并触发切换线路');
    }
  }

  _onTapChannel(Channel? model) {
    _currentChannel = model;
    _sourceIndex = 0;
    _autoEngineSwitchConsumed = false;
    if (_channelListModel != null && model != null) {
      _channelListModel!.playGroupIndex = model.groupIndex;
      _channelListModel!.playChannelIndex = model.channelIndex;
    }
    LogUtil.v('切换频道:::::${_currentChannel?.toJson()}');
    _playVideo('onTapChannel方法进入');
  }

  _playVideo(String entMsg) async {
    if (_currentChannel == null) return;
    _channelSerialNum = _currentChannel!.serialNum ?? 1;
    if (mounted) {
      context.read<ThemeProvider>().setPrePlaySerialNum(_channelSerialNum);
    }
    toastString = S.current.lineToast(_sourceIndex + 1, _currentChannel!.title ?? '');
    setState(() {});
    
    final url = _currentChannel!.urls![_sourceIndex > _currentChannel!.urls!.length - 1 ? 0 : _sourceIndex].toString();
    LogUtil.v('PlayVideo:【$entMsg】正在播放:$_sourceIndex::${_currentChannel!.toJson()}');
    
    try {
      final httpHeader = <String, String>{};
      
      // 优先使用频道级别的userAgent和headers
      if (_currentChannel != null) {
        // 使用频道级别的User-Agent
        if (_currentChannel!.userAgent != null && _currentChannel!.userAgent!.isNotEmpty) {
          httpHeader['User-Agent'] = _currentChannel!.userAgent!;
        }
        // 使用频道级别的headers
        else if (_currentChannel!.headers != null && _currentChannel!.headers!.isNotEmpty && _currentChannel!.headers!.containsKey('User-Agent')) {
          httpHeader['User-Agent'] = _currentChannel!.headers!['User-Agent']!;
        }
        // 添加频道级别的其他headers
        if (_currentChannel!.headers != null && _currentChannel!.headers!.isNotEmpty) {
          httpHeader.addAll(_currentChannel!.headers!);
        }
      }
      
      // 如果没有频道级别的User-Agent，使用全局的uaHint
      if (!httpHeader.containsKey('User-Agent') && _channelListModel != null && _channelListModel!.uaHint != null && _channelListModel!.uaHint!.isNotEmpty) {
        httpHeader['User-Agent'] = _channelListModel!.uaHint!;
      }

      LogUtil.v('播放请求头:::::$httpHeader');
      if (_useVlcPlayback) {
        if (_vlcPlayer == null) {
          await _bootstrapPlayback();
        }
        if (_vlcPlayer == null) return;
        final ua = httpHeader['User-Agent'];
        if (ua != null && ua.isNotEmpty) {
          _vlcPlayer!.setUserAgent(ua);
        }
        _vlcPlayer!.open(vlc.Media.network(url), autoStart: true);
      } else {
        if (_player == null) {
          await _bootstrapPlayback();
        }
        if (_player == null) return;
        await _player!.open(Media(url, httpHeaders: httpHeader));
        Future.microtask(() => applyMpvLiveTuning(_player!));
      }
      setState(() {
        toastString = S.current.loading;
      });
    } catch (e) {
      LogUtil.v('播放出错(catch):::::$e');
      _handleLineOrPlayError();
    }
  }

  _loadData() async {
    await _parseData(true);
    if (mounted) {
      if (context.read<ThemeProvider>().useAutoUpdate && Platform.isAndroid) {
        final url = await CheckVersionUtil.checkVersionAndAutoUpdate();
        if (mounted && url != null) {
          EasyLoading.showToast('新版本开始下载，稍后为您自动安装', toastPosition: EasyLoadingToastPosition.top);
          context.read<DownloadProvider>().downloadApk(url);
        }
      } else {
        if (context.read<ThemeProvider>().useLightVersionCheck) {
          CheckVersionUtil.checkLightVersion();
        } else {
          CheckVersionUtil.checkVersion(context, false, false);
        }
      }
    }
  }

  @override
  void dispose() {
    _playbackSettings?.removeListener(_onPlaybackSettingsChanged);
    WakelockPlus.disable();
    unawaited(_disposeMpvInternal());
    _disposeVlcInternal();
    super.dispose();
  }

  _parseData([bool isSkipRestSerialNum = false]) async {
    final resMap = await M3uUtil.getDefaultM3uData();
    _channelListModel = resMap;
    _sourceIndex = 0;
    if (mounted && !isSkipRestSerialNum) {
      context.read<ThemeProvider>().setPrePlaySerialNum(1);
    }
    if ((_channelListModel?.playList?.isNotEmpty) ?? false) {
      if (mounted) {
        final preNum = context.read<ThemeProvider>().prePlaySerialNum;
        final channel = M3uUtil.serialNumMap[preNum.toString()];
        _onTapChannel(channel ?? M3uUtil.serialNumMap['1']);
        if (_channelListModel!.type == PlayListType.m3u) {
          if (_channelListModel?.epgUrl != null && _channelListModel?.epgUrl != '') {
            EpgUtil.loadEPGXML(_channelListModel!.epgUrl!);
          }
        }
      }
    } else {
      unawaited(_disposeMpvInternal());
      _disposeVlcInternal();
      setState(() {
        _currentChannel = null;
        toastString = 'UNKNOWN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (EnvUtil.isTV()) {
      return TvPage(
        channelSerialNum: _channelSerialNum,
        channelListModel: _channelListModel,
        onTapChannel: _onTapChannel,
        toastString: toastString,
        controller: _playerController,
        isBuffering: isBuffering,
        isPlaying: isPlaying,
        aspectRatio: aspectRatio,
        onChangeSubSource: _parseData,
        changeChannelSources: _changeChannelSources,
      );
    }
    return Material(
      child: OrientationLayoutBuilder(
        portrait: (context) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          return MobileVideoWidget(
            toastString: toastString,
            controller: _useVlcPlayback ? null : _playerController,
            useVlc: _useVlcPlayback,
            vlcPlayer: _vlcPlayer,
            changeChannelSources: _changeChannelSources,
            isLandscape: false,
            isBuffering: isBuffering,
            isPlaying: isPlaying,
            aspectRatio: aspectRatio,
            onChangeSubSource: _parseData,
            drawChild: ChannelDrawerPage(channelListModel: _channelListModel, onTapChannel: _onTapChannel, isLandscape: false),
            onPreviousChannel: _previousChannel,
            onNextChannel: _nextChannel,
            onSwitchSource: _switchSource,
          );
        },
        landscape: (context) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              }
            },
            child: Scaffold(
              drawer: ChannelDrawerPage(channelListModel: _channelListModel, onTapChannel: _onTapChannel, isLandscape: true),
              drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.3,
              drawerScrimColor: Colors.transparent,
              onDrawerChanged: (bool isOpened) {
                setState(() {
                  _drawerIsOpen = isOpened;
                });
              },
              body: Builder(
                builder: (context) {
                  return CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.arrowUp): _previousChannel,
                      const SingleActivator(LogicalKeyboardKey.arrowDown): _nextChannel,
                      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _pushChannelDrawer(context),
                      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _switchSource(),
                      const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () => _changeChannelSources(),
                      if (Platform.isMacOS) const SingleActivator(LogicalKeyboardKey.comma, meta: true): () => _pushSettingPage(context),
                      if (Platform.isWindows || Platform.isLinux)
                        const SingleActivator(LogicalKeyboardKey.comma, control: true): () => _pushSettingPage(context),
                    },
                    child: Focus(
                      autofocus: true,
                      child: toastString == 'UNKNOWN'
                          ? InkWell(
                              canRequestFocus: false,
                              onTap: _parseData,
                              // onHover: (bool isHover) {
                              //   if (isHover) {
                              //     windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: true);
                              //   } else {
                              //     windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
                              //   }
                              // },
                              child: EmptyPage(
                                onRefresh: _parseData,
                                onEnterSetting: () async {
                                  await M3uUtil.openAddSource(context);
                                  _parseData();
                                },
                              ),
                            )
                          : TableVideoWidget(
                              toastString: toastString,
                              controller: _useVlcPlayback ? null : _playerController,
                              useVlc: _useVlcPlayback,
                              vlcPlayer: _vlcPlayer,
                              isBuffering: isBuffering,
                              isPlaying: isPlaying,
                              aspectRatio: aspectRatio,
                              drawerIsOpen: _drawerIsOpen,
                              changeChannelSources: _changeChannelSources,
                              onChangeSubSource: _parseData,
                              isLandscape: true,
                              onPreviousChannel: _previousChannel,
                              onNextChannel: _nextChannel,
                              onSwitchSource: _switchSource,
                            ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeChannelSources([FocusNode? videoNode]) async {
    LogUtil.v('_changeChannelSources:::::::::::');
    videoNode?.unfocus();
    List<String> sources = _currentChannel!.urls!;
    final selectedIndex = await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.black87,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
            color: Colors.transparent,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(sources.length, (index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FocusButton(
                      autofocus: _sourceIndex == index,
                      onTap: _sourceIndex == index
                          ? null
                          : () {
                              Navigator.pop(context, index);
                            },
                      title: S.current.lineIndex(index + 1),
                      selected: _sourceIndex == index,
                    ),
                    Positioned(
                      top: -2,
                      right: 8,
                      child: FutureBuilder<Color>(
                        future: LatencyCheckerUtil.checkLatencies(sources[index]),
                        initialData: Colors.transparent,
                        builder: (BuildContext context, AsyncSnapshot<Color> snapshot) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: snapshot.data, borderRadius: BorderRadius.circular(4)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
    videoNode?.requestFocus();
    if (selectedIndex != null && _sourceIndex != selectedIndex) {
      _sourceIndex = selectedIndex;
      LogUtil.v('切换线路:====线路${_sourceIndex + 1}');
      _playVideo('changeChannelSources方法进入');
    }
  }

  _nextChannel() async {
    if (toastString == 'UNKNOWN') return;
    final lastIndex = _channelSerialNum + 1;
    final channel = M3uUtil.serialNumMap[lastIndex.toString()];
    if (channel != null) {
      _channelListModel!.playChannelIndex = channel.channelIndex;
      _channelListModel!.playGroupIndex = channel.groupIndex;
      _onTapChannel.call(channel);
    } else {
      EasyLoading.showToast('已是最后一个节目');
    }
  }

  _previousChannel() async {
    if (toastString == 'UNKNOWN') return;
    final lastIndex = _channelSerialNum - 1;
    final channel = M3uUtil.serialNumMap[lastIndex.toString()];
    if (channel != null) {
      _channelListModel!.playChannelIndex = channel.channelIndex;
      _channelListModel!.playGroupIndex = channel.groupIndex;
      _onTapChannel.call(channel);
    } else {
      EasyLoading.showToast('已是第一个节目');
    }
  }

  _switchSource() async {
    if (toastString == 'UNKNOWN') return;
    _sourceIndex = (_sourceIndex + 1) % _currentChannel!.urls!.length;
    if (_currentChannel!.urls!.length == 1) {
      EasyLoading.showToast('🤣没有更多线路！');
    }
    _playVideo('switchSource点击屏幕切换线路方法进入');
  }

  _pushSettingPage(BuildContext context) async {
    LogUtil.v('设置：：：：');
    if (_useVlcPlayback) {
      _vlcPlayer?.pause();
    } else {
      _player?.pause();
    }
    await M3uUtil.openAddSource(context);
    final isChange = await M3uUtil.isChangeChannelLink();
    if (isChange) {
      _parseData();
    } else {
      if (_useVlcPlayback) {
        _vlcPlayer?.play();
      } else {
        _player?.play();
      }
    }
  }

  _pushChannelDrawer(BuildContext context) {
    if (toastString == 'UNKNOWN') return;
    LogUtil.v('节目菜单：：：：');
    Scaffold.of(context).openDrawer();
  }
}
