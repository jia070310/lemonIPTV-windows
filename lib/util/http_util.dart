import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_tv_live/util/log_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../generated/l10n.dart';

class HttpUtil {
  static final HttpUtil _instance = HttpUtil._();
  late Dio _dio;
  BaseOptions options = BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10));

  CancelToken cancelToken = CancelToken();

  factory HttpUtil() {
    return _instance;
  }

  HttpUtil._() {
    _dio = Dio(options)..interceptors.add(LogInterceptor(requestBody: true, requestHeader: false, responseBody: false, logPrint: LogUtil.v));
  }

  Future<T?> postRequest<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isShowLoading = true,
  }) async {
    // 先提取认证信息
    String url = extractCredentials(path, options);
    
    // 为GitHub链接添加加速器，但只对直接的GitHub链接添加，不对已经包含代理的链接添加
    if ((url.contains('github.com') || url.contains('raw.githubusercontent.com')) && 
        !url.contains('gh-proxy.org') && 
        !url.contains('gh.aptv.app') && 
        !url.contains('proxy') && 
        !url.contains('mirror')) {
      url = 'https://gh-proxy.org/$url';
    }
    
    LogUtil.v('PostRequest::::::$url');
    if (isShowLoading) EasyLoading.show();
    Response? response;
    try {
      response = await _dio.post<T>(url, data: data, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
      if (isShowLoading) EasyLoading.dismiss();
    } on DioException catch (e) {
      if (isShowLoading) EasyLoading.dismiss();
      formatError(e, isShowLoading);
    }
    return response?.data;
  }

  Future<T?> getRequest<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool isShowLoading = true,
  }) async {
    // 先提取认证信息
    String url = extractCredentials(path, options);
    
    // 为GitHub链接添加加速器，但只对直接的GitHub链接添加，不对已经包含代理的链接添加
    if ((url.contains('github.com') || url.contains('raw.githubusercontent.com')) && 
        !url.contains('gh-proxy.org') && 
        !url.contains('gh.aptv.app') && 
        !url.contains('proxy') && 
        !url.contains('mirror')) {
      url = 'https://gh-proxy.org/$url';
    }
    
    if (isShowLoading) EasyLoading.show();
    Response? response;
    try {
      response = await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      if (isShowLoading) EasyLoading.dismiss();
    } on DioException catch (e) {
      if (isShowLoading) EasyLoading.dismiss();
      formatError(e, isShowLoading);
    }
    return response?.data;
  }

  Future<int?> downloadFile(String url, String savePath, {ValueChanged<double>? progressCallback}) async {
    // 先提取认证信息
    Options options = Options(
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        HttpHeaders.acceptEncodingHeader: '*',
        HttpHeaders.userAgentHeader:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      },
    );
    String downloadUrl = extractCredentials(url, options);
    
    // 为GitHub链接添加加速器，但只对直接的GitHub链接添加，不对已经包含代理的链接添加
    if ((downloadUrl.contains('github.com') || downloadUrl.contains('raw.githubusercontent.com')) && 
        !downloadUrl.contains('gh-proxy.org') && 
        !downloadUrl.contains('gh.aptv.app') && 
        !downloadUrl.contains('proxy') && 
        !downloadUrl.contains('mirror')) {
      downloadUrl = 'https://gh-proxy.org/$downloadUrl';
    }
    
    Response? response;
    try {
      // await _dio.head(downloadUrl);
      response = await _dio.download(
        downloadUrl,
        savePath,
        options: options,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          progressCallback?.call((received / total));
        },
      );
      if (response.statusCode != 200) {
        throw DioException(requestOptions: response.requestOptions, error: 'status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      formatError(e, true);
    }
    return response?.statusCode ?? 500;
  }
}

String extractCredentials(String url, Options? options) {
  final uri = Uri.parse(url);
  if (uri.hasAuthority && uri.userInfo.isNotEmpty) {
    final base64Us = base64Encode(utf8.encode(uri.userInfo));
    options = options ?? Options();
    options.headers ??= {};
    options.headers![HttpHeaders.authorizationHeader] = 'Basic $base64Us';
    return url.replaceFirst('${uri.userInfo}@', '');
  }
  return url;
}

void formatError(DioException e, bool isShowLoading) {
  LogUtil.v('DioException>>>>>$e');
  if (!isShowLoading) return;
  if (e.type == DioExceptionType.connectionTimeout) {
    EasyLoading.showToast(S.current.netTimeOut);
  } else if (e.type == DioExceptionType.sendTimeout) {
    EasyLoading.showToast(S.current.netSendTimeout);
  } else if (e.type == DioExceptionType.receiveTimeout) {
    EasyLoading.showToast(S.current.netReceiveTimeout);
  } else if (e.type == DioExceptionType.badResponse) {
    EasyLoading.showToast(S.current.netBadResponse(e.response?.statusCode ?? ''));
  } else if (e.type == DioExceptionType.cancel) {
    EasyLoading.showToast(S.current.netCancel);
  } else {
    EasyLoading.showToast(e.message.toString());
  }
}
