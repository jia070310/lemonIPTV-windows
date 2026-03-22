import 'package:flutter/material.dart';

import '../entity/sub_scribe_model.dart';
import '../generated/l10n.dart';

class FocusCard extends StatefulWidget {
  final SubScribeModel model;
  final GestureTapCallback? onDelete;
  final GestureTapCallback? onUse;
  final ValueChanged<String>? onEditLink;
  final ValueChanged<String>? onEditName;
  final GestureTapCallback? onRefresh;

  const FocusCard({
    super.key,
    required this.model,
    required this.onDelete,
    this.onUse,
    this.onEditLink,
    this.onEditName,
    this.onRefresh,
  });

  @override
  State<FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends State<FocusCard> {
  _onFocusChange(bool isFocus) {
    if (isFocus) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.model.selected == true
            ? const Color(0xFFFFF44F).withOpacity(0.15)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.model.selected == true
              ? Colors.orange.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件名行
          Row(
            children: [
              if (widget.model.local == true)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '本地',
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: widget.model.link != 'default' ? _showEditNameDialog : null,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.model.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.model.link != 'default')
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 完整地址
          if (widget.model.link != null && widget.model.link!.isNotEmpty)
            GestureDetector(
              onTap: widget.model.link != 'default' ? _showEditLinkDialog : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.model.link!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.model.link != 'default')
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white.withOpacity(0.3),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // 创建时间和操作按钮
          Row(
            children: [
              Text(
                '${S.current.createTime}：${widget.model.time}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (widget.model.link != 'default')
                _buildActionButton(
                  icon: Icons.refresh,
                  label: '刷新',
                  onPressed: widget.onRefresh,
                ),
              if (widget.model.link != 'default')
                _buildActionButton(
                  icon: Icons.edit,
                  label: '编辑',
                  onPressed: _showEditLinkDialog,
                ),
              if (widget.model.selected != true && widget.model.link != 'default')
                _buildActionButton(
                  icon: Icons.delete,
                  label: '删除',
                  onPressed: () async {
                    final isDelete = await showDialog(
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
                                  color: const Color(0xFFFFF44F),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '确认删除',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            S.current.dialogDeleteContent,
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.6),
                              ),
                              child: Text(S.current.dialogCancel),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
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
                    if (isDelete == true) {
                      widget.onDelete?.call();
                    }
                  },
                ),
              _buildActionButton(
                icon: widget.model.selected == true ? Icons.check_circle : Icons.check_circle_outline,
                label: widget.model.selected == true ? '使用中' : '设为默认',
                isPrimary: widget.model.selected != true,
                onPressed: widget.model.selected != true ? widget.onUse : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: isPrimary ? Colors.orange : Colors.white.withOpacity(0.6),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isPrimary ? Colors.orange : Colors.white.withOpacity(0.6),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: isPrimary ? Colors.orange.withOpacity(0.1) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary
                ? BorderSide(color: Colors.orange.withOpacity(0.3))
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: widget.model.name ?? '');
    final newName = await showDialog<String>(
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
              const Text(
                '修改名称',
                style: TextStyle(
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
                '自定义名称方便识别订阅源',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
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
                    hintText: '输入名称（留空使用默认文件名）',
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
    if (newName != null) {
      widget.onEditName?.call(newName);
    }
  }

  Future<void> _showEditLinkDialog() async {
    final controller = TextEditingController(text: widget.model.link ?? '');
    final newLink = await showDialog<String>(
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
              const Text(
                '修改地址',
                style: TextStyle(
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
                '修改订阅源的链接地址',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
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
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: S.current.addFiledHintText,
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
    if (newLink != null && newLink.isNotEmpty) {
      widget.onEditLink?.call(newLink);
    }
  }
}
