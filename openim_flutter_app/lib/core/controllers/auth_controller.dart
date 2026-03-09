import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import '../api/auth_api.dart';
import '../api/api_client.dart';
import '../models/user_info.dart';

class AuthController extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoggedIn = false;
  bool _loading = false;
  String _error = '';
  String _lastReceptionistID = ''; // 二开：注册时绑定的接待员 userID

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  String get error => _error;
  String get lastReceptionistID => _lastReceptionistID;

  /// 将服务端错误码转化为用户可理解文案，禁止直接暴露技术术语
  /// 错误码来源：openim-chat/pkg/eerrs/predefine.go
  static String _mapError(int code, String serverMsg) {
    switch (code) {
      // ── openim-chat 业务错误码（20xxx）──────────────────────────────
      case 20001:
        return '手机号或密码错误，请重新输入';
      case 20002:
        return '该账号不存在，请先注册';
      case 20003:
        return '该手机号已注册，请直接登录';
      case 20004:
        return '该账号已注册，请直接登录';
      case 20005:
        return '验证码发送过于频繁，请稍后再试';
      case 20006:
        return '验证码错误，请重新输入';
      case 20007:
        return '验证码已过期，请重新获取';
      case 20008:
        return '验证码尝试次数过多，请重新获取';
      case 20009:
        return '验证码已使用，请重新获取';
      case 20010:
        return '邀请码已被使用，请更换后重试';
      case 20011:
        return '邀请码无效，请确认后重试';
      case 20012:
        return '账号已被禁止访问，请联系客服';
      case 20013:
        return '对方拒绝了好友申请';
      case 20014:
        return '该邮箱已注册，请直接登录';
      case 20101:
        return '登录状态已失效，请重新登录';
      // ── open-im-server 通用错误码 ────────────────────────────────────
      case 10001:
        return '输入信息有误，请检查后重试';
      case 10002:
        return '服务暂时不可用，请稍后重试';
      default:
        return '操作失败，请稍后重试';
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
        // errDlt 包含服务端详细信息（如白名单/锁定提示），code 20012 时优先展示
        final errDlt = res['errDlt']?.toString() ?? '';
        _error = errDlt.isNotEmpty && errCode == 20012
            ? errDlt
            : _mapError(errCode, res['errMsg']?.toString() ?? '');
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
    } on SocketException catch (e) {
      _error = kDebugMode
          ? '无法连接到服务器（${ApiConfig.chatApiBase}）: $e'
          : '无法连接到服务器，请检查网络设置';
    } catch (e) {
      _error = kDebugMode ? '登录异常: $e' : '登录失败，请稍后重试';
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

      // 二开：接待员绑定 — 注册成功后记录绑定的接待员 userID（如有）
      final data = res['data'] ?? {};
      _lastReceptionistID = data['receptionistID']?.toString() ?? '';

      _loading = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = '网络请求超时，请检查网络连接后重试';
    } on SocketException catch (e) {
      _error = kDebugMode
          ? '无法连接到服务器（${ApiConfig.chatApiBase}）: $e'
          : '无法连接到服务器，请检查网络设置';
    } catch (e) {
      _error = kDebugMode ? '注册异常: $e' : '注册失败，请稍后重试';
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    if (_error.isEmpty) return;
    _error = '';
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
