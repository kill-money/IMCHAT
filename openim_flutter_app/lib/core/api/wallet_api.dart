/// 钱包系统 — 用户端 API 封装（chat-api, port 10008）
library;

import 'api_client.dart';

class WalletApi {
  /// 获取当前用户钱包信息（余额等）
  static Future<Map<String, dynamic>> getWalletInfo() {
    return ChatApi.post('/wallet/info', {});
  }

  /// 获取当前用户绑定的银行卡列表
  static Future<Map<String, dynamic>> listCards() {
    return ChatApi.post('/wallet/cards', {});
  }

  /// 添加银行卡
  static Future<Map<String, dynamic>> addCard({
    required String bankName,
    required String cardNumber,
    required String cardHolder,
  }) {
    return ChatApi.post('/wallet/card/add', {
      'bankName': bankName,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
    });
  }

  /// 删除银行卡
  static Future<Map<String, dynamic>> removeCard({required String id}) {
    return ChatApi.post('/wallet/card/remove', {'id': id});
  }

  /// 提交提现申请（始终返回拒绝说明）
  static Future<Map<String, dynamic>> withdraw({
    required int amount,
    required String cardID,
    String note = '',
  }) {
    return ChatApi.post('/wallet/withdraw', {
      'amount': amount,
      'cardID': cardID,
      'note': note,
    });
  }
}
