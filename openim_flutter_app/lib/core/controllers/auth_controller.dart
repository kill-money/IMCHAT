import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import '../api/auth_api.dart';
import '../api/api_client.dart';
import '../models/user_info.dart';

class AuthController extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoggedIn = false;
  bool _loading = false;
  String _error = '';

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  String get error => _error;

  /// 将服务端错误码转化为用户可理解文案，禁止直接暴露技术术语
  static String _mapError(int code, String serverMsg) {
    switch (code) {
      case 1001:
        return '手机号或密码错误，请重新输入';
      case 1002:
        return '验证码错误或已过期';
      case 1003:
        return '该账号不存在，请先注册';
      case 1004:
        return '该手机号已注册，请直接登录';
      case 1005:
        return '邀请码无效，请确认后重试';
      case 10001:
        return '输入信息有误，请检查后重试';
      case 10002:
        return '服务暂时不可用，请稍后重试';
      default:
        return serverMsg.isNotEmpty ? serverMsg : '操作失败，请稍后重试';
    }
  }

  Future<bool> login({
    required String areaCode,
    required String phoneNumber,
    required String password,
    int platform = 1,
  }) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final res = await AuthApi.login(
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        password: password,
        platform: platform,
      );

      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _error = _mapError(errCode, res['errMsg']?.toString() ?? '');
        _loading = false;
        notifyListeners();
        return false;
      }

      final data = res['data'] ?? {};
      final chatToken = data['chatToken']?.toString() ?? '';
      final imToken = data['imToken']?.toString() ?? '';
      final userID = data['userID']?.toString() ?? '';
      final appRole = data['appRole'] is int ? data['appRole'] as int : 0;

      if (imToken.isEmpty || userID.isEmpty) {
        _error = '登录失败，服务器返回数据异常，请稍后重试';
        _loading = false;
        notifyListeners();
        return false;
      }

      ApiConfig.imToken = imToken;
      ApiConfig.chatToken = chatToken;
      ApiConfig.userID = userID;

      _currentUser = UserInfo(
        userID: userID,
        nickname: data['nickname']?.toString() ?? '',
        faceURL: data['faceURL']?.toString() ?? '',
        appRole: appRole,
      );
      _isLoggedIn = true;
      _loading = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = '网络请求超时，请检查网络连接后重试';
    } on SocketException {
      _error = '无法连接到服务器，请检查网络设置';
    } catch (_) {
      _error = '登录失败，请稍后重试';
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String nickname,
    required String areaCode,
    required String phoneNumber,
    required String password,
    String invitationCode = '',
  }) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final res = await AuthApi.register(
        nickname: nickname,
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        password: password,
        invitationCode: invitationCode.isEmpty ? null : invitationCode,
      );

      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _error = _mapError(errCode, res['errMsg']?.toString() ?? '');
        _loading = false;
        notifyListeners();
        return false;
      }

      _loading = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = '网络请求超时，请检查网络连接后重试';
    } on SocketException {
      _error = '无法连接到服务器，请检查网络设置';
    } catch (_) {
      _error = '注册失败，请稍后重试';
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  /// 供 UI 层设置客户端校验错误（如空字段检查）
  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    _error = '';
    ApiConfig.imToken = '';
    ApiConfig.chatToken = '';
    ApiConfig.userID = '';
    notifyListeners();
  }
}
