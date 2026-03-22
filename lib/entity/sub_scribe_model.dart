class SubScribeModel {
  SubScribeModel({
    this.time,
    this.link,
    this.selected = false,
    this.local = false,
    this.name,
  });

  SubScribeModel.fromJson(dynamic json) {
    time = json['time'];
    link = json['link'];
    selected = json['selected'] ?? false;
    local = json['local'] ?? false;
    name = json['name'];
  }
  String? time;
  String? link;
  bool? selected;
  bool? local;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['time'] = time;
    map['link'] = link;
    map['selected'] = selected ?? false;
    map['local'] = local ?? false;
    map['name'] = name;
    return map;
  }

  /// 获取显示名称，优先使用name，如果没有则使用文件名或链接
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    // 从link中提取文件名
    if (link != null && link!.isNotEmpty) {
      final uri = Uri.tryParse(link!);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
      // 如果不是URL，直接返回最后一部分
      final parts = link!.split(RegExp(r'[/\\]'));
      if (parts.isNotEmpty && parts.last.isNotEmpty) {
        return parts.last;
      }
    }
    return '未命名';
  }
}
