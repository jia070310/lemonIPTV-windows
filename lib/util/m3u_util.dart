import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_tv_live/entity/play_channel_list_model.dart';
import 'package:easy_tv_live/util/date_util.dart';
import 'package:easy_tv_live/util/env_util.dart';
import 'package:easy_tv_live/util/http_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp_util/sp_util.dart';

import '../entity/sub_scribe_model.dart';
import '../generated/l10n.dart';
import '../tv/tv_setting_page.dart';
import 'log_util.dart';

class M3uUtil {
  M3uUtil._();

  static final Map<String, Channel> _serialNumMap = {};

  static Map<String, Channel> get serialNumMap => _serialNumMap;

  static String? currentPlayChannelLink = '';

  // 获取默认的m3u文件
  static Future<PlayChannelListModel?> getDefaultM3uData() async {
    _serialNumMap.clear();
    String m3uData = '';
    final models = await getLocalData();
    if (models.isNotEmpty) {
      final defaultModel = models.firstWhere((element) => element.selected == true, orElse: () => models.first);
      currentPlayChannelLink = defaultModel.link;
      if (defaultModel.local == true) {
        File m3uFile = File(defaultModel.link!);
        final isExit = await m3uFile.exists();
        LogUtil.v('本地数据是否存在${defaultModel.link}::::::$isExit');
        if (isExit) {
          m3uData = await m3uFile.readAsString();
          await SpUtil.putString('m3u_cache', m3uData);
        } else {
          EasyLoading.showToast(S.current.noFile);
          return null;
        }
      } else {
        final newRes = await HttpUtil().getRequest(defaultModel.link == 'default' ? EnvUtil.videoDefaultChannelHost() : defaultModel.link!);
        if (newRes != null) {
          LogUtil.v('已获取新数据::::::');
          m3uData = newRes;
          await SpUtil.putString('m3u_cache', m3uData);
        } else {
          final oldRes = SpUtil.getString('m3u_cache', defValue: '');
          if (oldRes != '') {
            LogUtil.v('已获取到历史保存的数据::::::');
            m3uData = oldRes!;
          }
        }
      }
      if (m3uData.isEmpty) {
        return null;
      }
    } else {
      m3uData = await _fetchData();
      final defaultModel = SubScribeModel(
        time: DateUtil.formatDate(DateTime.now(), format: DateFormats.full),
        link: 'default',
        selected: true,
      );
      await saveLocalData([defaultModel]);
      currentPlayChannelLink = defaultModel.link;
    }
    String ua = '';
    if (currentPlayChannelLink!.startsWith('http')) {
      Uri.parse(currentPlayChannelLink!).queryParameters.forEach((key, value) {
        if (key == 'ua') {
          ua = value;
        }
      });
    }
    final channelModels = await _parseM3u(m3uData, ua);
    if (channelModels.playList!.isNotEmpty) {
      int index = 1;
      for (int i = 0; i < channelModels.playList!.length; i++) {
        final playModel = channelModels.playList![i];
        if (playModel.channel?.isNotEmpty ?? false) {
          for (int j = 0; j < playModel.channel!.length; j++) {
            final channel = playModel.channel![j];
            channel.serialNum = index;
            channel.groupIndex = i;
            channel.channelIndex = j;
            _serialNumMap[index.toString()] = channel;
            index += 1;
          }
        }
      }
    }
    return channelModels;
  }

  static Future<bool> isChangeChannelLink() async {
    final models = await getLocalData();
    final defaultModel = models.firstWhere((element) => element.selected == true, orElse: () => models.first);
    return currentPlayChannelLink != defaultModel.link;
  }

  // 获取本地m3u数据
  static Future<List<SubScribeModel>> getLocalData() async {
    Completer completer = Completer();
    List<SubScribeModel> m3uList = SpUtil.getObjList('local_m3u', (v) => SubScribeModel.fromJson(v), defValue: <SubScribeModel>[])!;
    completer.complete(m3uList);
    final res = await completer.future;
    return res;
  }

  // 保存本地m3u数据
  static Future<bool> saveLocalData(List<SubScribeModel> models) async {
    final res = await SpUtil.putObjectList('local_m3u', models.map((e) => e.toJson()).toList());
    return res ?? false;
  }

  static Future<String> _fetchData() async {
    final defaultM3u = EnvUtil.videoDefaultChannelHost();
    final res = await HttpUtil().getRequest(defaultM3u);
    if (res == null) {
      EasyLoading.showToast(S.current.getDefaultError);
      return '';
    } else {
      return res;
    }
  }

  static bool isLiveLink(String link) {
    final tLink = link.toLowerCase();
    if (tLink.startsWith('http') || tLink.startsWith('r') || tLink.startsWith('p') || tLink.startsWith('s') || tLink.startsWith('w')) {
      return true;
    }
    return false;
  }

  // 解析m3u文件
  static Future<PlayChannelListModel> _parseM3u(String m3u, String ua) async {
    final lines = m3u.split('\n');
    PlayChannelListModel playListModel = PlayChannelListModel(type: PlayListType.txt, playList: [], uaHint: ua);
    // 读取播放器设置
    final playerSettings = await _getPlayerSettings();
    final List<String> playerEpgUrls = playerSettings['epgUrls'] ?? [];
    final List<String> playerUserAgents = playerSettings['userAgents'] ?? [];
    
    if (m3u.startsWith('#EXTM3U') || m3u.startsWith('#EXTINF')) {
      playListModel.type = PlayListType.m3u;
      String tempGroupTitle = '';
      String tempChannelName = '';
      for (int i = 0; i < lines.length - 1; i++) {
        String line = lines[i];
        if (line.startsWith('#EXTM3U')) {
          List<String> params = line.replaceAll('"', '').split(' ');
          final tvgUrlParams = params.where((element) => element.startsWith('x-tvg-url')).toList();
          if (tvgUrlParams.isNotEmpty) {
            // 尝试多个x-tvg-url，直到找到正常的为止
            for (final tvgUrlParam in tvgUrlParams) {
              final tvgUrl = tvgUrlParam.split('=').last;
              // 处理一个x-tvg-url参数中包含多个用逗号分隔的URL的情况
              final tvgUrls = tvgUrl.split(',');
              for (final singleUrl in tvgUrls) {
                final trimmedUrl = singleUrl.trim();
                if (await _isValidEpgUrl(trimmedUrl)) {
                  playListModel.epgUrl = trimmedUrl;
                  break;
                }
              }
              // 如果已经找到有效的URL，就跳出循环
              if (playListModel.epgUrl != null) {
                break;
              }
            }
          }
        } else if (line.startsWith('#EXTINF:')) {
          if (line.startsWith('#EXTINF:-1,')) {
            line = line.replaceFirst('#EXTINF:-1,', '#EXTINF:-1 ');
          }
          final lineList = line.split(',');
          List<String> params = lineList.first.replaceAll('"', '').split(' ');
          final groupStr = params.firstWhere((element) => element.startsWith('group-title='), orElse: () => 'group-title=${S.current.defaultText}');
          String tvgLogo = params.firstWhere((element) => element.startsWith('tvg-logo='), orElse: () => '');
          String tvgId = params.firstWhere((element) => element.startsWith('tvg-name='), orElse: () => '');
          String userAgent = params.firstWhere((element) => element.startsWith('http-user-agent='), orElse: () => '');
          List<String> headerParams = params.where((element) => element.startsWith('http-header=')).toList();
          Map<String, String> headers = {};
          
          // 解析http-header参数
          for (final headerParam in headerParams) {
            final headerStr = headerParam.split('=').skip(1).join('=');
            final headerParts = headerStr.split(':');
            if (headerParts.length >= 2) {
              final key = headerParts[0].trim();
              final value = headerParts.skip(1).join(':').trim();
              headers[key] = value;
            }
          }
          
          // 如果M3U文件中没有指定userAgent，尝试使用播放器设置中的userAgents
          if (userAgent.isEmpty && playerUserAgents.isNotEmpty) {
            userAgent = playerUserAgents.first;
          }
          
          if (tvgId.isEmpty) {
            tvgId = params.firstWhere((element) => element.startsWith('tvg-id='), orElse: () => '');
          }
          if (tvgId.isNotEmpty) {
            tvgId = tvgId.split('=').last;
          }
          if (tvgLogo.isNotEmpty) {
            tvgLogo = tvgLogo.split('=').last;
          }
          if (userAgent.isNotEmpty) {
            userAgent = userAgent.split('=').skip(1).join('=');
          }
          if (groupStr.isNotEmpty) {
            tempGroupTitle = groupStr.split('=').last;
            tempChannelName = lineList.last;
            final playModel = playListModel.playList!.firstWhere(
              (model) => model.group == tempGroupTitle,
              orElse: () {
                final model = PlayModel(group: tempGroupTitle, channel: []);
                playListModel.playList!.add(model);
                return model;
              },
            );
            final channel = playModel.channel!.firstWhere(
              (element) => element.title == tempChannelName,
              orElse: () {
                final model = Channel(id: tvgId, logo: tvgLogo, title: tempChannelName, urls: [], userAgent: userAgent, headers: headers);
                playModel.channel!.add(model);
                return model;
              },
            );
            // 更新已存在的频道的userAgent和headers
            channel.userAgent = userAgent;
            channel.headers = headers;
            
            final lineNext = lines[i + 1];
            if (isLiveLink(lineNext)) {
              if (lineNext.contains('#')) {
                channel.urls!.addAll(lineNext.split('#'));
              } else {
                channel.urls!.add(lineNext);
              }
              i += 1;
            } else if (isLiveLink(lines[i + 2])) {
              if (lines[i + 2].contains('#')) {
                channel.urls!.addAll(lines[i + 2].split('#'));
              } else {
                channel.urls!.add(lines[i + 2].toString());
              }
              i += 2;
            }
          }
        } else if (isLiveLink(line)) {
          playListModel.playList!
              .firstWhere((model) => model.group == tempGroupTitle)
              .channel!
              .firstWhere((element) => element.title == tempChannelName)
              .urls!
              .add(line);
        } else if (line.startsWith('#UA-Hint')) {
          if (ua.isEmpty) {
            playListModel.uaHint = line.split(' ').firstWhere((item) => item.contains('/'));
          }
        }
      }
    } else {
      String tempGroup = S.current.defaultText;
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i];
        final lineList = line.split(',');
        if (lineList.length >= 2) {
          final groupTitle = lineList[0];
          final channelLink = lineList[1];
          if (isLiveLink(channelLink)) {
            final playModel = playListModel.playList!.firstWhere(
              (model) => model.group == tempGroup,
              orElse: () {
                final model = PlayModel(group: tempGroup, channel: []);
                playListModel.playList!.add(model);
                return model;
              },
            );
            // 对于txt格式的M3U文件，尝试使用播放器设置中的userAgents
            String userAgent = '';
            if (playerUserAgents.isNotEmpty) {
              userAgent = playerUserAgents.first;
            }
            final channel = playModel.channel!.firstWhere(
              (element) => element.title == groupTitle,
              orElse: () {
                final model = Channel(id: groupTitle, title: groupTitle, urls: [], userAgent: userAgent);
                playModel.channel!.add(model);
                return model;
              },
            );
            if (channelLink.contains('#')) {
              channel.urls!.addAll(channelLink.split('#'));
            } else {
              channel.urls!.add(channelLink);
            }
          } else {
            tempGroup = groupTitle == '' ? '${S.current.defaultText}${i + 1}' : groupTitle;
            int index = playListModel.playList!.indexWhere((e) => e.group == tempGroup);
            if (index == -1) {
              playListModel.playList!.add(PlayModel(group: tempGroup, channel: []));
            }
          }
        }
      }
    }

    // 如果M3U文件中没有指定epgUrl，尝试使用播放器设置中的epgUrls
    if (playListModel.epgUrl == null && playerEpgUrls.isNotEmpty) {
      for (final epgUrl in playerEpgUrls) {
        if (await _isValidEpgUrl(epgUrl)) {
          playListModel.epgUrl = epgUrl;
          break;
        }
      }
    }

    if (playListModel.playList!.isEmpty) {
      EasyLoading.showError(S.current.parseError);
    }
    if (playListModel.uaHint!.isNotEmpty) EasyLoading.showToast('User-Agent=${playListModel.uaHint}');
    return playListModel;
  }

  // 检查EPG URL是否有效
  static Future<bool> _isValidEpgUrl(String url) async {
    try {
      final response = await HttpUtil().getRequest(url, isShowLoading: false);
      return response != null && response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 读取播放器设置
  static Future<Map<String, dynamic>> _getPlayerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final epgUrlsJson = prefs.getString('playerEpgUrls');
      final userAgentsJson = prefs.getString('playerUserAgents');
      
      List<String> epgUrls = [];
      List<String> userAgents = [];
      
      if (epgUrlsJson != null) {
        epgUrls = List<String>.from(json.decode(epgUrlsJson));
      }
      
      if (userAgentsJson != null) {
        userAgents = List<String>.from(json.decode(userAgentsJson));
      }
      
      return {
        'epgUrls': epgUrls,
        'userAgents': userAgents
      };
    } catch (e) {
      print('读取播放器设置失败: $e');
      return {
        'epgUrls': [],
        'userAgents': []
      };
    }
  }

  static Future<bool?> openAddSource(BuildContext context) async {
    return Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const TvSettingPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, -1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }
}
