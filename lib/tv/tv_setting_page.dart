import 'package:easy_tv_live/setting/setting_font_page.dart';
import 'package:easy_tv_live/setting/setting_player_page.dart';
import 'package:easy_tv_live/setting/subscribe_page.dart';

import 'package:easy_tv_live/util/check_version_util.dart';
import 'package:flutter/material.dart';

import '../setting/setting_beautify_page.dart';

class TvSettingPage extends StatefulWidget {
  const TvSettingPage({super.key});

  @override
  State<TvSettingPage> createState() => _TvSettingPageState();
}

class _TvSettingPageState extends State<TvSettingPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: Scaffold(
            appBar: AppBar(title: const Text('设置')),
            body: Column(
              children: [
                Flexible(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.subscriptions),
                        title: const Text('订阅资源'),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.font_download),
                        title: const Text('字体设置'),
                        selected: _selectedIndex == 1,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.apps),
                        title: Text('功能设置 ${CheckVersionUtil.latestVersionEntity == null ? '' : '🔴'}'),
                        selected: _selectedIndex == 2,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.play_circle),
                        title: const Text('播放器设置'),
                        subtitle: Text(
                          '内核 / 软解 / EPG / UA',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        selected: _selectedIndex == 3,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: Text('V${CheckVersionUtil.version}')),
              ],
            ),
          ),
        ),
        if (_selectedIndex == 0) const Expanded(child: SubScribePage(isTV: true)),
        if (_selectedIndex == 1) const Expanded(child: SettingFontPage(isTV: true)),
        if (_selectedIndex == 2) const Expanded(child: SettingBeautifyPage()),
        if (_selectedIndex == 3) const Expanded(child: SettingPlayerPage()),
      ],
    );
  }
}
