import 'dart:io';

import 'package:easy_tv_live/util/date_util.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:easy_tv_live/util/m3u_util.dart';
import 'package:easy_tv_live/widget/focus_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as p;
import 'package:sp_util/sp_util.dart';

import '../entity/sub_scribe_model.dart';
import '../generated/l10n.dart';
import '../util/env_util.dart';

class SubScribePage extends StatefulWidget {
  final bool isTV;

  const SubScribePage({super.key, this.isTV = false});

  @override
  State<SubScribePage> createState() => _SubScribePageState();
}

class _SubScribePageState extends State<SubScribePage> {
  List<SubScribeModel> _m3uList = <SubScribeModel>[];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getData();
    _pasteClipboard();
  }

  _getData() async {
    final res = await M3uUtil.getLocalData();
    setState(() {
      _m3uList = res;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _pasteClipboard() async {
    if (EnvUtil.isTV()) return;
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipText = clipData?.text;
    if (clipText != null &&
        clipText.startsWith('http') &&
        !clipText.endsWith('.json')) {
      final res = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2022),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                Text(
                  S.current.dialogTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.dataSourceContent,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    clipText,
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.6),
                ),
                child: Text(S.current.dialogCancel),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    S.current.dialogConfirm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          );
        },
      );
      if (res == true) {
        await _pareUrl(clipText);
      }
      Clipboard.setData(const ClipboardData(text: ''));
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
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.subscriptions, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              S.current.subscribe,
              style: const TextStyle(
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
        child: Column(
          children: [
            // 订阅列表
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                controller: _scrollController,
                itemBuilder: (context, index) {
                  final model = _m3uList[index];
                  return FocusCard(
                    model: model,
                    onDelete: () async {
                      _m3uList.removeAt(index);
                      await M3uUtil.saveLocalData(_m3uList);
                      setState(() {});
                    },
                    onUse: () async {
                      for (var element in _m3uList) {
                        element.selected = false;
                      }
                      if (model.selected != true) {
                        model.selected = true;
                        await SpUtil.remove('m3u_cache');
                        await M3uUtil.saveLocalData(_m3uList);
                        setState(() {});
                      }
                    },
                    onEditLink: (val) async {
                      model.link = val;
                      await M3uUtil.saveLocalData(_m3uList);
                      setState(() {});
                    },
                    onEditName: (val) async {
                      model.name = val.isEmpty ? null : val;
                      await M3uUtil.saveLocalData(_m3uList);
                      setState(() {});
                    },
                    onRefresh: () async {
                      EasyLoading.show(status: '刷新中...');
                      await SpUtil.remove('m3u_cache');
                      model.time = DateUtil.formatDate(
                        DateTime.now(),
                        format: DateFormats.full,
                      );
                      await M3uUtil.saveLocalData(_m3uList);
                      setState(() {});
                      EasyLoading.showSuccess('刷新成功');
                    },
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemCount: _m3uList.length,
              ),
            ),
            // 底部按钮区域
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.folder_open,
                      label: '本地添加',
                      onPressed: _addLocalM3u,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.add_link,
                      label: '网络添加',
                      onPressed: _addM3uSource,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? LinearGradient(
                        colors: [
                          Colors.orange,
                          Colors.orange.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isPrimary ? null : (isHovered ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimary ? Colors.orange.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                ),
                boxShadow: isPrimary && isHovered
                    ? [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? Colors.white : Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : Colors.white.withOpacity(0.9),
                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _addLocalM3u() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8', 'txt'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = p.basename(file.path);
      LogUtil.v('添加本地订阅源::::：${file.path}');
      
      // 检查是否已存在
      final hasIndex = _m3uList.indexWhere(
        (element) => element.link == file.path,
      );
      LogUtil.v('添加:hasIndex:::：$hasIndex');
      if (hasIndex != -1) {
        EasyLoading.showToast(S.current.addRepeat);
        return;
      }

      // 弹出文件名输入对话框
      final customName = await _showNameInputDialog(
        defaultName: fileName,
        title: '添加本地订阅源',
        hint: '输入名称（留空使用文件名）',
      );
      
      if (customName == null) return; // 用户取消

      final sub = SubScribeModel(
        time: DateUtil.formatDate(DateTime.now(), format: DateFormats.full),
        link: file.path,
        selected: false,
        local: true,
        name: customName.isEmpty ? null : customName,
      );
      _m3uList.add(sub);
      await M3uUtil.saveLocalData(_m3uList);
      setState(() {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.positions.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }
  }

  _addM3uSource() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final urlController = TextEditingController();
        final nameController = TextEditingController();
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E2022),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      S.current.addDataSource,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (urlController.text.trim().isEmpty) {
                          EasyLoading.showToast('请输入订阅地址');
                          return;
                        }
                        Navigator.pop(context, {
                          'url': urlController.text.trim(),
                          'name': nameController.text.trim(),
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          S.current.dialogConfirm,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // URL输入框
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: urlController,
                  autofocus: true,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: S.current.addFiledHintText,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 名称输入框
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: nameController,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '输入名称（留空自动提取文件名）',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 20,
              ),
            ],
          ),
        );
      },
    );
    
    if (result == null) return;
    
    final url = result['url']!;
    final name = result['name']!;
    
    LogUtil.v('添加网络订阅源::::：$url');
    final hasIndex = _m3uList.indexWhere((element) => element.link == url);
    LogUtil.v('添加:hasIndex:::：$hasIndex');
    if (hasIndex != -1) {
      EasyLoading.showToast(S.current.addRepeat);
      return;
    }
    if (url.startsWith('http') && hasIndex == -1) {
      LogUtil.v('添加：$url');
      final sub = SubScribeModel(
        time: DateUtil.formatDate(DateTime.now(), format: DateFormats.full),
        link: url,
        selected: false,
        name: name.isEmpty ? null : name,
      );
      _m3uList.add(sub);
      await M3uUtil.saveLocalData(_m3uList);
      setState(() {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.positions.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    } else {
      EasyLoading.showToast(S.current.addNoHttpLink);
    }
  }

  _pareUrl(String res) async {
    LogUtil.v('添加网络订阅源::::：$res');
    final hasIndex = _m3uList.indexWhere((element) => element.link == res);
    LogUtil.v('添加:hasIndex:::：$hasIndex');
    if (hasIndex != -1) {
      EasyLoading.showToast(S.current.addRepeat);
      return;
    }
    if (res.startsWith('http') && hasIndex == -1) {
      LogUtil.v('添加：$res');
      final sub = SubScribeModel(
        time: DateUtil.formatDate(DateTime.now(), format: DateFormats.full),
        link: res,
        selected: false,
      );
      _m3uList.add(sub);
      await M3uUtil.saveLocalData(_m3uList);
      setState(() {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.positions.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    } else {
      EasyLoading.showToast(S.current.addNoHttpLink);
    }
  }

  Future<String?> _showNameInputDialog({
    required String defaultName,
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2022),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '默认文件名: $defaultName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.6),
              ),
              child: Text(S.current.dialogCancel),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context, controller.text.trim()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  S.current.dialogConfirm,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
