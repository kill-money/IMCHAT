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

      // Check API-level error first
      final errCode = res['errCode'] ?? 0;
      if (errCode != 0) {
        _error = '登录失败: ${res['errMsg'] ?? '未知错误'}';
        _loading = false;
        notifyListeners();
        return false;
      }

      final data = res['data'] ?? {};
      final chatToken = data['chatToken'] ?? '';
      final imToken = data['imToken'] ?? '';
      final userID = data['userID'] ?? '';
      final appRole = data['appRole'] is int ? data['appRole'] as int : 0;

      if (imToken.isEmpty || userID.isEmpty) {
        _error = '登录失败: 服务器返回数据不完整';
        _loading = false;
        notifyListeners();
        return false;
      }

      ApiConfig.imToken = imToken;
      ApiConfig.chatToken = chatToken;
      ApiConfig.userID = userID;

      _currentUser = UserInfo(
        userID: userID,
        nickname: data['nickname'] ?? '',
        faceURL: data['faceURL'] ?? '',
        appRole: appRole,
      );
      _isLoggedIn = true;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '登录失败: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
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
      await AuthApi.register(
        nickname: nickname,
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        password: password,
        invitationCode: invitationCode,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '注册失败: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    ApiConfig.imToken = '';
    ApiConfig.chatToken = '';
    ApiConfig.userID = '';
    notifyListeners();
  }
}
