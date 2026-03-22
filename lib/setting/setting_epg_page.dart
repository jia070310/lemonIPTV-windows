import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_tv_live/util/epg_util.dart';

class SettingEpgPage extends StatefulWidget {
  const SettingEpgPage({super.key});

  @override
  State<SettingEpgPage> createState() => _SettingEpgPageState();
}

class _SettingEpgPageState extends State<SettingEpgPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<EpgSource> _epgSources = [];
  String? _currentEpgUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEpgSources();
  }

  Future<void> _loadEpgSources() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final epgSourcesJson = prefs.getString('epgSources');
      if (epgSourcesJson != null) {
        _epgSources = EpgSource.fromJsonList(epgSourcesJson);
      }
      _currentEpgUrl = prefs.getString('currentEpgUrl');
    } catch (e) {
      print('加载节目表源失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEpgSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('epgSources', EpgSource.toJsonList(_epgSources));
    } catch (e) {
      print('保存节目表源失败: $e');
    }
  }

  Future<void> _addEpgSource() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (url.isEmpty || name.isEmpty) {
      _showSnackBar('请输入节目表名称和地址');
      return;
    }

    // 检查URL是否有效
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showSnackBar('请输入有效的URL地址');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 尝试加载节目表，验证URL是否有效
      await EpgUtil.loadEPGXML(url);
      
      // 添加到列表
      _epgSources.add(EpgSource(name: name, url: url));
      await _saveEpgSources();
      
      // 清空输入框
      _urlController.clear();
      _nameController.clear();
      
      _showSnackBar('节目表添加成功');
    } catch (e) {
      print('添加节目表失败: $e');
      _showSnackBar('节目表添加失败，请检查URL是否正确');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEpgSource(int index) async {
    setState(() {
      _epgSources.removeAt(index);
    });
    await _saveEpgSources();
    _showSnackBar('节目表删除成功');
  }

  Future<void> _switchEpgSource(String url) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await EpgUtil.loadEPGXML(url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentEpgUrl', url);
      _currentEpgUrl = url;
      _showSnackBar('节目表切换成功');
    } catch (e) {
      print('切换节目表失败: $e');
      _showSnackBar('节目表切换失败，请检查网络连接');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('节目表管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('添加节目表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '节目表名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: '节目表地址',
                      border: OutlineInputBorder(),
                      hintText: '支持XML或GZ格式，多个地址用逗号分隔',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addEpgSource,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('添加节目表'),
                  ),
                  const SizedBox(height: 24),
                  const Text('已添加的节目表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_epgSources.isEmpty)
                    const Center(
                      child: Text('暂无节目表，请添加节目表源'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _epgSources.length,
                        itemBuilder: (context, index) {
                          final source = _epgSources[index];
                          final isCurrent = _currentEpgUrl == source.url;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(source.name),
                              subtitle: Text(source.url),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrent)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text('当前使用', style: TextStyle(color: Colors.green)),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteEpgSource(index),
                                  ),
                                ],
                              ),
                              onTap: () => _switchEpgSource(source.url),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class EpgSource {
  final String name;
  final String url;

  EpgSource({required this.name, required this.url});

  factory EpgSource.fromJson(Map<String, dynamic> json) {
    return EpgSource(
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }

  static List<EpgSource> fromJsonList(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => EpgSource.fromJson(json)).toList();
    } catch (e) {
      print('解析节目表源失败: $e');
      return [];
    }
  }

  static String toJsonList(List<EpgSource> sources) {
    try {
      final List<Map<String, dynamic>> jsonList = sources.map((source) => source.toJson()).toList();
      return json.encode(jsonList);
    } catch (e) {
      print('序列化节目表源失败: $e');
      return '[]';
    }
  }
}
