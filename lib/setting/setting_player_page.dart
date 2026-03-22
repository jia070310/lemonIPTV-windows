import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/playback_settings_provider.dart';
import '../util/mpv_live_helper.dart';
import '../util/playback_engine.dart';

class SettingPlayerPage extends StatefulWidget {
  const SettingPlayerPage({super.key});

  @override
  State<SettingPlayerPage> createState() => _SettingPlayerPageState();
}

class _SettingPlayerPageState extends State<SettingPlayerPage> {
  final TextEditingController _epgUrlController = TextEditingController();
  final TextEditingController _uaController = TextEditingController();
  List<String> _epgUrls = [];
  List<String> _userAgents = [];
  bool _isLoading = false;
  bool _preferSoftwareDecode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final epgUrlsJson = prefs.getString('playerEpgUrls');
      if (epgUrlsJson != null) {
        _epgUrls = List<String>.from(json.decode(epgUrlsJson));
      }
      final userAgentsJson = prefs.getString('playerUserAgents');
      if (userAgentsJson != null) {
        _userAgents = List<String>.from(json.decode(userAgentsJson));
      }
      _preferSoftwareDecode = preferSoftwareDecode;
    } catch (e) {
      print('加载播放器设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('playerEpgUrls', json.encode(_epgUrls));
      await prefs.setString('playerUserAgents', json.encode(_userAgents));
    } catch (e) {
      print('保存播放器设置失败: $e');
    }
  }

  Future<void> _addEpgUrl() async {
    final url = _epgUrlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('请输入节目表链接');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showSnackBar('请输入有效的URL地址');
      return;
    }

    setState(() {
      _epgUrls.add(url);
      _epgUrlController.clear();
    });
    await _saveSettings();
    _showSnackBar('节目表链接添加成功');
  }

  Future<void> _removeEpgUrl(int index) async {
    setState(() {
      _epgUrls.removeAt(index);
    });
    await _saveSettings();
    _showSnackBar('节目表链接删除成功');
  }

  Future<void> _addUserAgent() async {
    final ua = _uaController.text.trim();
    if (ua.isEmpty) {
      _showSnackBar('请输入User-Agent');
      return;
    }

    setState(() {
      _userAgents.add(ua);
      _uaController.clear();
    });
    await _saveSettings();
    _showSnackBar('User-Agent添加成功');
  }

  Future<void> _removeUserAgent(int index) async {
    setState(() {
      _userAgents.removeAt(index);
    });
    await _saveSettings();
    _showSnackBar('User-Agent删除成功');
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2B2D30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFFFF44F),
              ),
            )
          : Container(
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
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.play_circle_filled,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '播放器设置',
                              style: TextStyle(
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
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Player Settings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
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
                              if (isVlcPlaybackSupported) ...[
                                _buildSectionHeader(
                                  '播放内核',
                                  Colors.cyan,
                                  'Engine',
                                ),
                                const SizedBox(height: 8),
                                Consumer<PlaybackSettingsProvider>(
                                  builder: (context, playback, _) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RadioListTile<PlaybackEngine>(
                                          value: PlaybackEngine.mpv,
                                          groupValue: playback.engine,
                                          onChanged: (v) async {
                                            if (v != null) {
                                              await playback.setEngine(v);
                                            }
                                          },
                                          title: const Text('mpv（默认）'),
                                          subtitle: Text(
                                            '内置 libmpv',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.45),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        RadioListTile<PlaybackEngine>(
                                          value: PlaybackEngine.vlc,
                                          groupValue: playback.engine,
                                          onChanged: (v) async {
                                            if (v != null) {
                                              await playback.setEngine(v);
                                            }
                                          },
                                          title: const Text('VLC（libVLC）'),
                                          subtitle: Text(
                                            '与独立 VLC 相近，部分源更流畅（仅 Windows / Linux）',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.45),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                                  child: Text(
                                    '切换内核后请切换频道或重新打开当前频道。',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              _buildSectionHeader(
                                '解码与画质',
                                Colors.teal,
                                'Decode',
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '优先软解（缓解部分花屏）',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'mpv / VLC 均会尽量使用软解设置。改后请切换频道生效。',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.45),
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _preferSoftwareDecode,
                                      activeTrackColor: Colors.teal.withValues(alpha: 0.5),
                                      activeThumbColor: Colors.tealAccent,
                                      onChanged: (v) async {
                                        await setPreferSoftwareDecode(v);
                                        setState(() {
                                          _preferSoftwareDecode = v;
                                        });
                                        _showSnackBar(
                                          v ? '已开启软解，请切换频道或重新打开当前频道生效' : '已恢复硬解，请切换频道或重新打开当前频道生效',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              // 自定义节目表链接模块
                              _buildSectionHeader(
                                '自定义节目表链接',
                                Colors.orange,
                                'EPG Sources',
                              ),
                              const SizedBox(height: 16),
                              // 输入组
                              _buildInputGroup(
                                controller: _epgUrlController,
                                hintText: '请输入节目表 (XML/M3U) 链接',
                                icon: Icons.link,
                                buttonText: '添加',
                                buttonColor: Colors.orange,
                                onPressed: _addEpgUrl,
                              ),
                              const SizedBox(height: 16),
                              // 节目表列表
                              if (_epgUrls.isNotEmpty)
                                ..._epgUrls.asMap().entries.map((entry) {
                                  return _buildListItem(
                                    text: entry.value,
                                    index: entry.key,
                                    onDelete: () => _removeEpgUrl(entry.key),
                                    accentColor: Colors.orange,
                                  );
                                }).toList(),
                              if (_epgUrls.isEmpty)
                                _buildEmptyState('暂无节目表链接，请添加'),
                              const SizedBox(height: 32),
                              // 自定义User-Agent模块
                              _buildSectionHeader(
                                '自定义 User-Agent',
                                const Color(0xFFFFF44F),
                                null,
                              ),
                              const SizedBox(height: 16),
                              // 输入组
                              _buildInputGroup(
                                controller: _uaController,
                                hintText: '例如: aliplayer',
                                icon: Icons.person_outline,
                                buttonText: '添加',
                                buttonColor: Colors.blue,
                                onPressed: _addUserAgent,
                              ),
                              const SizedBox(height: 16),
                              // User-Agent列表
                              if (_userAgents.isNotEmpty)
                                ..._userAgents.asMap().entries.map((entry) {
                                  return _buildUserAgentItem(
                                    text: entry.value,
                                    index: entry.key,
                                    onDelete: () => _removeUserAgent(entry.key),
                                  );
                                }).toList(),
                              if (_userAgents.isEmpty)
                                _buildEmptyState('暂无User-Agent，请添加'),
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
                                    color: Colors.green.withOpacity(0.5),
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
                            const Text(
                              'Build 2026.0206',
                              style: TextStyle(
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
                              '配置将自动保存至本地',
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

  Widget _buildInputGroup({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  icon,
                  color: Colors.white30,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  buttonColor,
                  buttonColor.withRed((buttonColor.red * 0.8).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required String text,
    required int index,
    required VoidCallback onDelete,
    required Color accentColor,
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
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isHovered ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF44F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAgentItem({
    required String text,
    required int index,
    required VoidCallback onDelete,
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isHovered ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
      ),
    );
  }
}
