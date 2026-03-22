import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart'
    show ChangeNotifier, debugPrint, kDebugMode;
import 'package:flutter/services.dart' show MissingPluginException;
import '../api/auth_api.dart';
import '../api/api_client.dart';
import '../models/user_info.dart';
import '../services/device_info_service.dart';
import '../services/auth_storage_service.dart';

class AuthController extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoggedIn = false;
  bool _loading = false;
  String _error = '';
  String _lastReceptionistID = ''; // 注册时绑定的接待员 userID

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  String get error => _error;
  String get lastReceptionistID => _lastReceptionistID;

  void debugPrintState() {
    debugPrint(
        '[AuthController] loggedIn=$_isLoggedIn loading=$_loading userID=${_currentUser?.userID} error=$_error');
  }

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
      // ── 白名单专属错误码（20015-20016）──────────────────────────────
      case 20015:
        return '该账号未加入登录白名单，请联系管理员开通';
      case 20016:
        return '您的白名单账号已被停用，请联系管理员恢复';
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
  }) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final platform = getCurrentPlatformId();
    final deviceID = await getOrCreateDeviceId();

    try {
      final res = await AuthApi.login(
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        password: password,
        platform: platform,
        deviceID: deviceID,
      );

      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        // 白名单专属错误码（20015/20016）直接使用本地化文案，不显示后端 errDlt
        // 其他 20012（账号禁止）仍可附带 errDlt 补充说明
        if (errCode == 20015 || errCode == 20016) {
          _error = _mapError(errCode, '');
        } else {
          _error = _mapError(errCode, res['errMsg']?.toString() ?? '');
        }
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
      debugPrint(
          '[IM_INIT] 登录成功: userID=$userID imToken=${imToken.substring(0, 20)}... chatToken=${chatToken.isNotEmpty ? chatToken.substring(0, 20) : "EMPTY"}...');
      debugPrint(
          '[IM_INIT] API基址: im=${ApiConfig.imApiBase} chat=${ApiConfig.chatApiBase}');

      _currentUser = UserInfo(
        userID: userID,
        nickname: data['nickname']?.toString() ?? '',
        faceURL: data['faceURL']?.toString() ?? '',
        appRole: appRole,
        isUserAdmin: data['isUserAdmin'] == true, // 推荐系统管理员
      );
      _isLoggedIn = true;
      _loading = false;
      // 持久化 Session，避免重启重新登录产生重复登录记录
      await AuthStorageService.save(
        imToken: imToken,
        chatToken: chatToken,
        userID: userID,
        nickname: _currentUser!.nickname,
        faceURL: _currentUser!.faceURL,
        appRole: appRole,
        isUserAdmin: _currentUser!.isUserAdmin,
      );
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = '网络请求超时，请检查网络连接后重试';
    } on SocketException catch (e) {
      _error = kDebugMode
          ? '无法连接到服务器（${ApiConfig.chatApiBase}）: $e'
          : '无法连接到服务器，请检查网络设置';
    } on MissingPluginException {
      _error = '系统组件加载异常，请重启应用后重试';
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
    String downloadReferrer = '', // 推荐人 ID（来自下载链接 ?ref=）
  }) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final platform = getCurrentPlatformId();
    final deviceID = await getOrCreateDeviceId();

    try {
      final res = await AuthApi.register(
        nickname: nickname,
        areaCode: areaCode,
        phoneNumber: phoneNumber,
        password: password,
        invitationCode: invitationCode.isEmpty ? null : invitationCode,
        downloadReferrer: downloadReferrer.isEmpty ? null : downloadReferrer,
        platform: platform,
        deviceID: deviceID,
      );

      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        _error = _mapError(errCode, res['errMsg']?.toString() ?? '');
        _loading = false;
        notifyListeners();
        return false;
      }

      // 接待员绑定 — 注册成功后记录绑定的接待员 userID（如有）
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
    } on MissingPluginException {
      _error = '系统组件加载异常，请重启应用后重试';
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

  /// 从服务端重新拉取当前用户信息（appRole / isUserAdmin 等字段可能被管理员更改）
  /// 登录后应定期调用，确保权限状态与服务端同步
  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn || ApiConfig.userID.isEmpty) return;
    try {
      final res = await ChatApi.post('/user/find/full', {
        'userIDs': [ApiConfig.userID],
      });
      final users = res['data']?['users'] as List?;
      if (users == null || users.isEmpty) return;
      final raw = users.first as Map<String, dynamic>?;
      if (raw == null) return;

      // 从 IM 服务器获取 ex 字段（签名等扩展信息）
      Map<String, dynamic> merged = {...raw};
      try {
        final imRes = await ImApi.post('/user/get_users_info', {
          'userIDs': [ApiConfig.userID],
        });
        if ((imRes['errCode'] ?? 0) == 0) {
          final imData = imRes['data'];
          final List imUsers;
          if (imData is List) {
            imUsers = imData;
          } else if (imData is Map) {
            imUsers = (imData['usersInfo'] as List?) ??
                (imData['users'] as List?) ??
                [];
          } else {
            imUsers = [];
          }
          if (imUsers.isNotEmpty) {
            final imRaw = imUsers.first as Map<String, dynamic>;
            // 仅合并 IM 服务器独有的字段（ex、globalRecvMsgOpt 等）
            if (imRaw.containsKey('ex')) merged['ex'] = imRaw['ex'];
          }
        }
      } catch (e) {
        debugPrint('[AuthCtrl] IM ex 字段获取失败: $e');
      }

      _currentUser = UserInfo.fromJson({
        ..._currentUser!.toJson(),
        ...merged,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthCtrl] refreshUserInfo 失败: $e');
    }
  }

  /// 在 API 更新成功后同步本地用户信息，避免重新登录
  void updateLocalUser({
    String? nickname,
    String? faceURL,
    int? gender,
    String? signature,
    int? birth,
  }) {
    if (_currentUser == null) return;
    _currentUser = UserInfo(
      userID: _currentUser!.userID,
      nickname: nickname ?? _currentUser!.nickname,
      faceURL: faceURL ?? _currentUser!.faceURL,
      gender: gender ?? _currentUser!.gender,
      phoneNumber: _currentUser!.phoneNumber,
      email: _currentUser!.email,
      createTime: _currentUser!.createTime,
      signature: signature ?? _currentUser!.signature,
      birth: birth ?? _currentUser!.birth,
      appRole: _currentUser!.appRole,
      isUserAdmin: _currentUser!.isUserAdmin,
      isOfficial: _currentUser!.isOfficial,
    );
    notifyListeners();
  }

  /// 启动时尝试从持久化存储恢复 Session。
  /// 返回 true 表示恢复成功并已进入已登录状态；false 表示需要重新登录。
  Future<bool> tryRestoreSession() async {
    final session = await AuthStorageService.load();
    if (session == null) return false;

    // 用缓存数据填充 ApiConfig — 后续 API 调用将使用这些 Token
    final imToken = session['imToken'] as String? ?? '';
    final chatToken = session['chatToken'] as String? ?? '';
    final userID = session['userID'] as String? ?? '';
    if (imToken.isEmpty || userID.isEmpty) return false;

    ApiConfig.imToken = imToken;
    ApiConfig.chatToken = chatToken;
    ApiConfig.userID = userID;

    // 用缓存数据临时构建 currentUser（避免闪屏无头像）
    _currentUser = UserInfo(
      userID: userID,
      nickname: session['nickname'] as String? ?? '',
      faceURL: session['faceURL'] as String? ?? '',
      appRole: (session['appRole'] as int?) ?? 0,
      isUserAdmin: session['isUserAdmin'] == true,
    );

    // 向服务端轻量验证 Token（/user/find/full），失败则清除缓存
    try {
      final res = await ChatApi.post('/user/find/full', {
        'userIDs': [userID],
      });
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        await AuthStorageService.clear();
        _currentUser = null;
        ApiConfig.imToken = '';
        ApiConfig.chatToken = '';
        ApiConfig.userID = '';
        return false;
      }
      // 用服务端最新数据更新缓存用户信息
      final users = res['data']?['users'] as List?;
      if (users != null && users.isNotEmpty) {
        final raw = users.first as Map<String, dynamic>? ?? {};
        _currentUser = UserInfo.fromJson({
          ..._currentUser!.toJson(),
          ...raw,
        });
        // 刷新持久化存储中的用户信息
        await AuthStorageService.save(
          imToken: imToken,
          chatToken: chatToken,
          userID: userID,
          nickname: _currentUser!.nickname,
          faceURL: _currentUser!.faceURL,
          appRole: _currentUser!.appRole,
          isUserAdmin: _currentUser!.isUserAdmin,
        );
      }
    } catch (_) {
      // 网络不可用时仍允许离线使用缓存 Token（下次联网时会自然过期）
    }

    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    _error = '';
    ApiConfig.imToken = '';
    ApiConfig.chatToken = '';
    ApiConfig.userID = '';
    // 清除持久化 Session
    await AuthStorageService.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    // 当前无需清理的资源，但保留 dispose 以确保子类或未来扩展的安全
    super.dispose();
  }
}
