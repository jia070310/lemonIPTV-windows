import 'dart:io';

import 'package:apk_installer/apk_installer.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../util/env_util.dart';
import '../util/http_util.dart';

class DownloadProvider extends ChangeNotifier {
  bool _isDownloading = false;
  double _progress = 0.0;

  bool get isDownloading => _isDownloading;
  double get progress => _progress;

  Future<void> downloadApk(String url) async {
    _isDownloading = true;
    notifyListeners();

    final savePath = '${(await getTemporaryDirectory()).path}/apk/${url.split('/').last}';
    LogUtil.v('download apk :::: $url');
    LogUtil.v('apk save path:::: $savePath');

    final code = await HttpUtil().downloadFile(url, savePath, progressCallback: (double currentProgress) {
      _progress = currentProgress;
      notifyListeners();
    });
    if (code == 200) {
      _isDownloading = false;
      await ApkInstaller.installApk(filePath: savePath);
      notifyListeners();
    } else {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Windows端下载并安装更新
  Future<void> downloadAndInstallWindowsUpdate(String url, {VoidCallback? onComplete}) async {
    _isDownloading = true;
    _progress = 0.0;
    notifyListeners();

    try {
      // 获取下载目录
      final directory = await getDownloadsDirectory();
      final fileName = url.split('/').last;
      final savePath = '${directory?.path ?? (await getTemporaryDirectory()).path}/$fileName';
      
      LogUtil.v('download windows update :::: $url');
      LogUtil.v('save path:::: $savePath');

      // 下载文件（使用代理）
      final code = await HttpUtil().downloadFile(
        url,
        savePath,
        progressCallback: (double currentProgress) {
          _progress = currentProgress;
          notifyListeners();
        },
      );
      
      if (code == 200) {
        _isDownloading = false;
        notifyListeners();
        
        LogUtil.v('download complete, starting installer:::: $savePath');
        
        // 启动安装程序
        if (Platform.isWindows) {
          // 使用cmd启动安装程序，/S参数表示静默安装（如果安装包支持）
          final result = await Process.start('cmd', ['/c', 'start', '/wait', savePath]);
          LogUtil.v('installer started with pid:::: ${result.pid}');
        }
        
        onComplete?.call();
      } else {
        _isDownloading = false;
        notifyListeners();
        LogUtil.e('download failed with code:::: $code');
      }
    } catch (e) {
      _isDownloading = false;
      notifyListeners();
      LogUtil.e('download error:::: $e');
    }
  }
}
