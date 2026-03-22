import 'dart:io';
import 'dart:async';

import 'package:easy_tv_live/provider/theme_provider.dart';
import 'package:easy_tv_live/setting/qr_scan_page.dart';
import 'package:easy_tv_live/setting/reward_page.dart';
import 'package:easy_tv_live/setting/setting_font_page.dart';
import 'package:easy_tv_live/setting/subscribe_page.dart';
import 'package:easy_tv_live/util/env_util.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:sp_util/sp_util.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'generated/l10n.dart';
import 'live_home_page.dart';
import 'provider/download_provider.dart';
import 'provider/playback_settings_provider.dart';
import 'router_keys.dart';
import 'setting/setting_page.dart';
import 'setting/setting_epg_page.dart';
import 'setting/setting_player_page.dart';
import 'util/epg_util.dart';
import 'util/vlc_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!EnvUtil.isMobile) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1500, 845),
      minimumSize: Size(800, 450),
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: '极简TV',
    );
    // 等待窗口准备好再显示，避免闪烁
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  WakelockPlus.enable();
  LogUtil.init(isDebug: kDebugMode, tag: 'EasyTV');
  await SpUtil.getInstance();
  await EpgUtil.initEpg();
  MediaKit.ensureInitialized();
  initVlcIfDesktop();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackSettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }
}

// 自定义窗口按钮
class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: Colors.black,
        onPressed: onPressed,
        hoverColor: isClose ? Colors.red : Colors.black12,
        padding: EdgeInsets.zero,
        splashRadius: 23,
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  bool _isFullScreen = false;
  bool _showTitleBar = false;
  Timer? _titleBarTimer;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux) {
      windowManager.addListener(this);
      _updateFullScreenState();
    }
  }

  @override
  void dispose() {
    _titleBarTimer?.cancel();
    if (Platform.isWindows || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
  }

  Future<void> _updateFullScreenState() async {
    if (mounted) {
      bool isFullScreen = await windowManager.isFullScreen();
      setState(() {
        _isFullScreen = isFullScreen;
      });
    }
  }

  void _showTempTitleBar() {
    setState(() {
      _showTitleBar = true;
    });
    _titleBarTimer?.cancel();
    _titleBarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTitleBar = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
      ThemeProvider,
      ({String fontFamily, double textScaleFactor})
    >(
      selector: (_, provider) => (
        fontFamily: provider.fontFamily,
        textScaleFactor: provider.textScaleFactor,
      ),
      builder: (context, data, child) {
        String? fontFamily = data.fontFamily;
        if (fontFamily == 'system') {
          fontFamily = null;
        }
        return MaterialApp(
          title: '柠檬TV',
          theme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFF44F),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
            ),
            useMaterial3: true,
          ),
          routes: {
            RouterKeys.subScribe: (BuildContext context) =>
                const SubScribePage(),
            RouterKeys.setting: (BuildContext context) => const SettingPage(),
            RouterKeys.settingFont: (BuildContext context) =>
                const SettingFontPage(),

            RouterKeys.settingQrScan: (BuildContext context) =>
                const QrScanPage(),
            RouterKeys.settingEpg: (BuildContext context) =>
                const SettingEpgPage(),
            RouterKeys.settingPlayer: (BuildContext context) =>
                const SettingPlayerPage(),
          },
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return const Locale('en', 'US');
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode &&
                  supportedLocale.countryCode != locale.countryCode) {
                return supportedLocale;
              }
            }
            return const Locale('en', 'US');
          },
          debugShowCheckedModeBanner: false,
          home: Platform.isWindows || Platform.isLinux
              ? DragToResizeArea(
                  child: Stack(
                    children: [
                      // 主内容区域(带顶部padding为标题栏留空间)
                      Positioned(
                        top: 32,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: const LiveHomePage(),
                      ),
                      // 自定义标题栏(放在Stack最上层)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 32,
                        child: MouseRegion(
                          onEnter: (_) {
                            if (_isFullScreen) {
                              _showTempTitleBar();
                            }
                          },
                          child: Visibility(
                            visible: !_isFullScreen || _showTitleBar,
                            child: DragToMoveArea(
                              child: Container(
                                color: const Color(0xFFfde100),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    // Logo图标(使用assets中的logo)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '柠檬TV',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    // 最小化按钮
                                    _WindowButton(
                                      icon: Icons.minimize,
                                      onPressed: () => windowManager.minimize(),
                                    ),
                                    // 最大化/还原按钮
                                    _WindowButton(
                                      icon: Icons.crop_square,
                                      onPressed: () async {
                                        if (await windowManager.isMaximized()) {
                                          windowManager.unmaximize();
                                        } else {
                                          windowManager.maximize();
                                        }
                                      },
                                    ),
                                    // 关闭按钮
                                    _WindowButton(
                                      icon: Icons.close,
                                      onPressed: () => windowManager.close(),
                                      isClose: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const LiveHomePage(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(data.textScaleFactor)),
              child: FlutterEasyLoading(child: child),
            );
          },
        );
      },
    );
  }
}
