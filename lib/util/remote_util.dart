import 'dart:io';

import 'log_util.dart';

class RemoteUtil {
  static Future<String?> getCurrentIP() async {
    try {
      // 首先尝试使用 NetworkInterface 获取IP地址
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // 跳过回环地址
          if (addr.isLoopback) continue;
          
          // 优先返回192.168.x.x或10.x.x.x或172.16.x.x - 172.31.x.x的地址
          final ip = addr.address;
          if (ip.startsWith('192.168.') || 
              ip.startsWith('10.') || 
              (ip.startsWith('172.') && 
               int.parse(ip.split('.')[1]) >= 16 && 
               int.parse(ip.split('.')[1]) <= 31)) {
            return ip;
          }
        }
      }
      
      // 如果没有找到私有IP，返回第一个非回环地址
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
      
      return null;
    } catch (e) {
      LogUtil.e('获取本机IP失败: $e');
      return null;
    }
  }
}
