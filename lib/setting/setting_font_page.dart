import 'dart:convert';

import 'package:easy_tv_live/provider/theme_provider.dart';
import 'package:easy_tv_live/util/font_util.dart';
import 'package:easy_tv_live/util/http_util.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../entity/font_model.dart';
import '../util/env_util.dart';

class SettingFontPage extends StatefulWidget {
  final bool isTV;
  const SettingFontPage({super.key, this.isTV = false});

  @override
  State<SettingFontPage> createState() => _SettingFontPageState();
}

class _SettingFontPageState extends State<SettingFontPage> {
  final _fontLink = EnvUtil.fontLink();
  final _fontList = <FontModel>[];
  final _fontScales = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0];

  @override
  void initState() {
    _loadFontList();
    super.initState();
  }

  _loadFontList() async {
    final res = await HttpUtil().getRequest('$_fontLink/font.json');
    if (res != null) {
      try {
        _fontList.clear();
        List val = json.decode(res);
        _fontList.addAll(val.map((e) => FontModel.fromJson(e)).toList());
        if (mounted) setState(() {});
      } catch (e) {
        LogUtil.e(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        elevation: 0,
        leading: widget.isTV ? const SizedBox.shrink() : null,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF44F),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.font_download, color: Colors.blue, size: 22),
            const SizedBox(width: 8),
            const Text(
              '字体设置',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
        child: Consumer<ThemeProvider>(builder: (BuildContext context, ThemeProvider themeProvider, Widget? child) {
          return Column(
            children: [
              // 字体大小设置
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '字体大小',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            '当前: ${themeProvider.textScaleFactor}x',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        _fontScales.length,
                        (index) => _buildScaleButton(
                          scale: _fontScales[index],
                          isSelected: themeProvider.textScaleFactor == _fontScales[index],
                          onTap: () {
                            themeProvider.setTextScale(_fontScales[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 字体列表标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '字体列表',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_fontList.length} 个字体',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 字体列表
              Expanded(
                child: ListView.separated(
                  itemCount: _fontList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final model = _fontList[index];
                    return _buildFontItem(
                      model: model,
                      themeProvider: themeProvider,
                      onTap: () async {
                        if (model.progress != 0.0) return;
                        if (model.fontKey == 'system') {
                          themeProvider.setFontFamily(model.fontKey!);
                          return;
                        }
                        final fontUrl = '$_fontLink/fonts/${model.fontKey!}.${model.fontType}';
                        debugPrint('FontItem::::onTap::::$fontUrl');
                        final res = await FontUtil().loadFont(
                          fontUrl,
                          model.fontKey!,
                          progressCallback: (double progress) {
                            LogUtil.v('progress=========$progress');
                            setState(() {
                              model.progress = progress;
                            });
                          },
                        );
                        if (res && context.mounted) {
                          setState(() {
                            model.progress = 0.0;
                          });
                          themeProvider.setFontFamily(model.fontKey!, fontUrl);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildScaleButton({
    required double scale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '${scale}x',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildFontItem({
    required FontModel model,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    final isSelected = themeProvider.fontFamily == model.fontKey;
    final isDownloading = model.progress != 0.0;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: isSelected ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : isHovered
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.3)
                      : isHovered
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      height: 72,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.font_download_outlined,
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.white.withOpacity(0.5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  model.fontName!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                if (isSelected)
                                  Text(
                                    '当前正在使用',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.withOpacity(0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isDownloading)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF44F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '下载中 ${(model.progress! * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.blue.withOpacity(0.8),
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSelected ? '使用中' : '使用',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (model.progress! > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: model.progress,
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
