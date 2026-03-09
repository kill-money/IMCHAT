/// 二开：钱包系统 — 数据模型
library;

class WalletAccount {
  final String userID;
  final int balance; // 分（cents）
  final String currency;
  final DateTime? updatedAt;

  const WalletAccount({
    required this.userID,
    required this.balance,
    required this.currency,
    this.updatedAt,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    return WalletAccount(
      userID: json['userID']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'CNY',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// 余额（元），保留两位小数
  String get balanceYuan => (balance / 100).toStringAsFixed(2);
}

class BankCard {
  final String id;
  final String bankName;
  final String cardNumber; // 脱敏后4位
  final String cardHolder;

  const BankCard({
    required this.id,
    required this.bankName,
    required this.cardNumber,
    required this.cardHolder,
  });

  factory BankCard.fromJson(Map<String, dynamic> json) {
    return BankCard(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      cardNumber: json['cardNumber']?.toString() ?? '',
      cardHolder: json['cardHolder']?.toString() ?? '',
    );
  }
}
