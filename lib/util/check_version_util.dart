import 'dart:convert';
import 'dart:io';

import 'package:easy_tv_live/widget/update_download_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';
import 'env_util.dart';
import 'http_util.dart';
import 'log_util.dart';

class CheckVersionUtil {
  static const version = '1.1.5';
  static final releaseLink = EnvUtil.sourceReleaseHost();
  static final homeLink = EnvUtil.sourceHomeHost();
  static VersionEntity? latestVersionEntity;
  static bool isTV = EnvUtil.isTV();

  static Future<String?> checkVersionAndAutoUpdate() async {
    final latestVersionEntity = await checkRelease(false, false);
    if (latestVersionEntity != null) {
      // 优先使用versions.json中指定的下载链接
      if (latestVersionEntity.downloadUrl != null && latestVersionEntity.downloadUrl!.isNotEmpty) {
        return latestVersionEntity.downloadUrl;
      }
      
      // 如果没有指定下载链接，使用默认生成规则
      String fileName;
      if (Platform.isWindows) {
        fileName = 'lemonTV-${latestVersionEntity.latestVersion}-windows-x64.exe';
      } else if (Platform.isAndroid) {
        fileName = 'easyTV-${latestVersionEntity.latestVersion}${isTV ? '-tv' : ''}.apk';
      } else {
        fileName = 'easyTV-${latestVersionEntity.latestVersion}.apk';
      }
      final url = '${EnvUtil.sourceDownloadHost()}/${latestVersionEntity.latestVersion}/$fileName';
      return url;
    }
    return null;
  }

  static checkLightVersion() async {
    final latestVersionEntity = await checkRelease(false, false);
    if (latestVersionEntity != null) {
      EasyLoading.showToast('发现新版本，请及时更新哦！', toastPosition: EasyLoadingToastPosition.top);
    }
  }

  static Future<VersionEntity?> checkRelease([bool isShowLoading = true, isShowLatestToast = true]) async {
    if (latestVersionEntity != null) return latestVersionEntity;
    try {
      final res = await HttpUtil().getRequest(EnvUtil.checkVersionHost(), isShowLoading: isShowLoading);
      if (res != null) {
        final resMap = json.decode(res);
        
        // 根据平台获取对应的版本信息
        String platformKey;
        if (Platform.isWindows) {
          platformKey = 'windows';
        } else if (Platform.isAndroid) {
          platformKey = 'android';
        } else if (Platform.isMacOS) {
          platformKey = 'macos';
        } else if (Platform.isLinux) {
          platformKey = 'linux';
        } else {
          platformKey = 'android'; // 默认使用安卓配置
        }
        
        // 检查是否有平台特定的配置
        Map<String, dynamic>? platformData;
        if (resMap.containsKey(platformKey)) {
          platformData = resMap[platformKey] as Map<String, dynamic>?;
        }
        
        // 如果没有平台特定配置，使用旧版格式兼容
        final latestVersion = platformData?['latest_version'] as String? ?? resMap['latest_version'] as String?;
        final updateLog = platformData?['update_log'] as List? ?? resMap['update_log'] as List?;
        final latestMsg = updateLog?.join('\n');
        final downloadUrl = platformData?['download_url'] as String?;
        
        if (latestVersion != null && latestVersion.compareTo(version) > 0) {
          latestVersionEntity = VersionEntity(latestVersion: latestVersion, latestMsg: latestMsg, downloadUrl: downloadUrl);
          return latestVersionEntity;
        } else {
          if (isShowLatestToast) EasyLoading.showToast(S.current.latestVersion, toastPosition: EasyLoadingToastPosition.top);
          LogUtil.v('已是最新版::::::::');
        }
      }
      return null;
    } catch (e) {
      LogUtil.e('检查更新错误:::::$e');
      return null;
    }
  }

  static Future<bool?> showUpdateDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: isTV || !EnvUtil.isMobile ? 600 : 300,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2D30),
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xff6D6875), Color(0xffB4838D), Color(0xffE5989B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text('${S.current.findNewVersion}🚀', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(minHeight: 200, minWidth: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎒 v${CheckVersionUtil.latestVersionEntity!.latestVersion}${S.current.updateContent}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      Padding(padding: const EdgeInsets.all(20), child: Text('${CheckVersionUtil.latestVersionEntity!.latestMsg}')),
                    ],
                  ),
                ),
                UpdateDownloadBtn(
                  downloadUrl: _getDownloadUrl(),
                  onDownloadComplete: () {
                    // Windows端下载完成后退出应用
                    if (Platform.isWindows) {
                      exit(0);
                    }
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getDownloadUrl() {
    // 优先使用versions.json中指定的下载链接
    if (latestVersionEntity?.downloadUrl != null && latestVersionEntity!.downloadUrl!.isNotEmpty) {
      return latestVersionEntity!.downloadUrl!;
    }
    
    // 如果没有指定下载链接，使用默认生成规则
    final version = latestVersionEntity!.latestVersion;
    if (Platform.isWindows) {
      return '${EnvUtil.sourceDownloadHost()}/$version/lemonTV-$version-windows-x64.exe';
    } else if (Platform.isAndroid) {
      return '${EnvUtil.sourceDownloadHost()}/$version/easyTV-$version${isTV ? '-tv' : ''}.apk';
    } else {
      return '${EnvUtil.sourceDownloadHost()}/$version/easyTV-$version.apk';
    }
  }

  static checkVersion(BuildContext context, [bool isShowLoading = true, isShowLatestToast = true]) async {
    final res = await checkRelease(isShowLoading, isShowLatestToast);
    if (res != null && context.mounted) {
      final isUpdate = await showUpdateDialog(context);
      if (isUpdate == true && !Platform.isAndroid) {
        launchBrowserUrl(releaseLink);
      }
    }
  }

  static launchBrowserUrl(String url) async {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class VersionEntity {
  final String? latestVersion;
  final String? latestMsg;
  final String? downloadUrl;

  VersionEntity({this.latestVersion, this.latestMsg, this.downloadUrl});
}
