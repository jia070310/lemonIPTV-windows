import 'dart:io';

import 'package:easy_tv_live/provider/download_provider.dart';
import 'package:easy_tv_live/util/env_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';

class UpdateDownloadBtn extends StatefulWidget {
  final String downloadUrl;
  final VoidCallback? onDownloadComplete;

  const UpdateDownloadBtn({
    super.key,
    this.downloadUrl = '',
    this.onDownloadComplete,
  });

  @override
  State<UpdateDownloadBtn> createState() => _UpdateDownloadBtnState();
}

class _UpdateDownloadBtnState extends State<UpdateDownloadBtn> {
  bool _isFocusDownload = true;
  double btnWidth = EnvUtil.isTV() ? 400 : 260;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (BuildContext context, DownloadProvider provider, Widget? child) {
        return provider.isDownloading
            ? ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: SizedBox(
                  height: 44,
                  width: btnWidth,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: LinearProgressIndicator(
                          value: provider.progress,
                          backgroundColor: const Color(0xFFFFF44F).withOpacity(0.2),
                          color: Colors.redAccent,
                        ),
                      ),
                      Text('下载中...${(provider.progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              )
            : child!;
      },
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: Size(btnWidth, 44),
          backgroundColor: _isFocusDownload ? Colors.redAccent : Colors.redAccent.withOpacity(0.3),
          elevation: _isFocusDownload ? 10 : 0,
          overlayColor: Colors.transparent,
        ),
        autofocus: true,
        onFocusChange: (bool isFocus) {
          setState(() {
            _isFocusDownload = isFocus;
          });
        },
        onPressed: () {
          if (Platform.isAndroid) {
            context.read<DownloadProvider>().downloadApk(widget.downloadUrl);
          } else if (Platform.isWindows) {
            // Windows端直接下载并安装
            context.read<DownloadProvider>().downloadAndInstallWindowsUpdate(
              widget.downloadUrl,
              onComplete: widget.onDownloadComplete,
            );
          } else {
            Navigator.of(context).pop(true);
          }
        },
        child: Text(S.current.update, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
