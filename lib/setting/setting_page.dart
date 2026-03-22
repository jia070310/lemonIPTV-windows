import 'package:easy_tv_live/router_keys.dart';
import 'package:easy_tv_live/util/check_version_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import '../provider/theme_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  VersionEntity? _latestVersionEntity = CheckVersionUtil.latestVersionEntity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0a0a0a),
              const Color(0xFF1a1a1a),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF44F),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.settings,
                        color: Color(0xFFFFF44F),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        S.current.settings,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF44F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFF44F).withOpacity(0.3)),
                        ),
                        child: Text(
                          'v${CheckVersionUtil.version}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFFF44F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 关于应用模块
                        _buildSectionHeader(
                          '关于应用',
                          const Color(0xFFFFF44F),
                          'About',
                        ),
                        const SizedBox(height: 16),
                        _buildSettingItem(
                          icon: Icons.home_filled,
                          title: S.current.homePage,
                          onTap: () {
                            CheckVersionUtil.launchBrowserUrl(CheckVersionUtil.homeLink);
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.history,
                          title: S.current.releaseHistory,
                          onTap: () {
                            CheckVersionUtil.launchBrowserUrl(CheckVersionUtil.releaseLink);
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.tips_and_updates,
                          title: S.current.checkUpdate,
                          trailing: _latestVersionEntity != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF44F),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    S.current.newVersion(_latestVersionEntity!.latestVersion!),
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                )
                              : null,
                          onTap: () async {
                            await CheckVersionUtil.checkVersion(context);
                            setState(() {
                              _latestVersionEntity = CheckVersionUtil.latestVersionEntity;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        // 功能设置模块
                        _buildSectionHeader(
                          '功能设置',
                          const Color(0xFFFFF44F),
                          'Features',
                        ),
                        const SizedBox(height: 16),
                        _buildSettingItem(
                          icon: Icons.text_fields,
                          title: '字体设置',
                          onTap: () {
                            Navigator.pushNamed(context, RouterKeys.settingFont);
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.calendar_month,
                          title: '节目表管理',
                          onTap: () {
                            Navigator.pushNamed(context, RouterKeys.settingEpg);
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.play_circle,
                          title: '播放器设置',
                          onTap: () {
                            Navigator.pushNamed(context, RouterKeys.settingPlayer);
                          },
                        ),
                        const SizedBox(height: 32),
                        // 系统设置模块
                        _buildSectionHeader(
                          '系统设置',
                          const Color(0xFFFFF44F),
                          'System',
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchItem(
                          icon: Icons.image,
                          title: '背景美化',
                          subtitle: '未播放时的屏幕背景,每日更换图片',
                          value: context.watch<ThemeProvider>().isBingBg,
                          onChanged: (value) {
                            context.read<ThemeProvider>().setBingBg(value);
                          },
                        ),
                        _buildSwitchItem(
                          icon: Icons.notifications_off,
                          title: '更新提示免打扰',
                          subtitle: '开启后,播放页面的更新弹窗将会变成普通的消息提醒',
                          value: context.watch<ThemeProvider>().useLightVersionCheck,
                          onChanged: (value) {
                            context.read<ThemeProvider>().setLightVersionCheck(value);
                          },
                        ),
                        _buildSwitchItem(
                          icon: Icons.system_update,
                          title: '自动更新',
                          subtitle: '发现新版本将会自动下载并安装',
                          value: context.watch<ThemeProvider>().useAutoUpdate,
                          onChanged: (value) {
                            context.read<ThemeProvider>().setAutoUpdate(value);
                          },
                        ),
                        const SizedBox(height: 32),
                        // 网络设置模块
                        _buildSectionHeader(
                          '网络设置',
                          const Color(0xFFFFF44F),
                          'Network',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownItem(
                          icon: Icons.vpn_key,
                          title: '数据代理',
                          subtitle: 'Github访问受限的用户需开启',
                          value: context.watch<ThemeProvider>().useDataValueProxy,
                          items: [
                            DropdownMenuItem(value: 0, child: Text('关闭', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 1, child: Text('代理1', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 2, child: Text('代理2', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 3, child: Text('代理3', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              context.read<ThemeProvider>().setDataValueProxy(value);
                            }
                          },
                        ),
                        _buildDropdownItem(
                          icon: Icons.timer,
                          title: '超时自动切换线路',
                          subtitle: '超过多少秒未播放则自动切换下一个线路',
                          value: context.watch<ThemeProvider>().timeoutSwitchLine,
                          items: [
                            DropdownMenuItem(value: 5, child: Text('5s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 10, child: Text('10s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 15, child: Text('15s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 20, child: Text('20s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 30, child: Text('30s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                            DropdownMenuItem(value: 60, child: Text('60s', style: TextStyle(color: Colors.white.withOpacity(0.8)))),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              context.read<ThemeProvider>().setTimeoutSwitchLine(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 底部状态栏
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF44F),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFF44F).withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'System Ready',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '|',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Build ${CheckVersionUtil.version}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.white30,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '柠檬TV - IPTV播放器',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor, String? tag) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white.withOpacity(0.6),
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.6),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFFFFF44F),
                  activeTrackColor: const Color(0xFFFFF44F).withOpacity(0.3),
                  inactiveThumbColor: Colors.white.withOpacity(0.5),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.6),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButton<T>(
                    value: value,
                    underline: const SizedBox.shrink(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
                    dropdownColor: const Color(0xFF2B2D30),
                    style: const TextStyle(color: Colors.white),
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
