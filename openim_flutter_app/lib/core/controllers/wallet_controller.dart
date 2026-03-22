/// 钱包系统 — WalletController (ChangeNotifier)
library;

import 'package:flutter/foundation.dart';
import '../api/wallet_api.dart';
import '../models/wallet.dart';

class WalletController extends ChangeNotifier {
  WalletAccount? _account;
  List<BankCard> _cards = [];
  bool _loading = false;
  String _error = '';

  WalletAccount? get account => _account;
  List<BankCard> get cards => List.unmodifiable(_cards);
  bool get loading => _loading;
  String get error => _error;

  void debugPrintState() {
    debugPrint(
        '[WalletController] loading=$_loading balance=${_account?.balance} cards=${_cards.length} error=$_error');
  }

  Future<void> loadWallet() async {
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      final res = await WalletApi.getWalletInfo();
      if ((res['errCode'] ?? 0) == 0) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        _account = WalletAccount.fromJson(data);
      } else {
        _error = '加载失败，请稍后重试';
      }
    } catch (e) {
      _error = '网络错误';
      if (kDebugMode) debugPrint('loadWallet error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCards() async {
    try {
      final res = await WalletApi.listCards();
      if ((res['errCode'] ?? 0) == 0) {
        final list = res['data']?['list'] as List? ?? [];
        _cards = list
            .map((e) => BankCard.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadCards error: $e');
    }
  }

  Future<bool> addCard({
    required String bankName,
    required String cardNumber,
    required String cardHolder,
  }) async {
    try {
      final res = await WalletApi.addCard(
          bankName: bankName, cardNumber: cardNumber, cardHolder: cardHolder);
      if ((res['errCode'] ?? 0) == 0) {
        await loadCards();
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('addCard error: $e');
    }
    return false;
  }

  Future<bool> removeCard(String id) async {
    try {
      final res = await WalletApi.removeCard(id: id);
      if ((res['errCode'] ?? 0) == 0) {
        _cards.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('removeCard error: $e');
    }
    return false;
  }

  /// 提现 — 始终返回拒绝消息
  Future<String> withdraw({required int amount, required String cardID}) async {
    try {
      final res = await WalletApi.withdraw(amount: amount, cardID: cardID);
      if ((res['errCode'] ?? 0) == 0) {
        final msg = res['data']?['message']?.toString();
        return msg ?? '提现申请已提交';
      }
      return '操作失败，请稍后重试';
    } catch (_) {
      return '网络错误，请稍后重试';
    }
  }

  @override
  void dispose() {
    _cards.clear();
    super.dispose();
  }
}
