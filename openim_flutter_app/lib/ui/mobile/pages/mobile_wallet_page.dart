/// 二开：钱包系统 — 用户端钱包页面（移动端）
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/wallet_controller.dart';
import '../../../core/models/wallet.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/ui/app_button.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';

class MobileWalletPage extends StatefulWidget {
  const MobileWalletPage({super.key});

  @override
  State<MobileWalletPage> createState() => _MobileWalletPageState();
}

class _MobileWalletPageState extends State<MobileWalletPage> {
  @override
  void initState() {
    super.initState();
    final wallet = context.read<WalletController>();
    wallet.loadWallet();
    wallet.loadCards();
  }

  void _showAddCardDialog() {
    final bankCtrl = TextEditingController();
    final cardCtrl = TextEditingController();
    final holderCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加银行卡'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(labelText: '银行名称'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '卡号'),
                maxLength: 19,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: holderCtrl,
                decoration: const InputDecoration(labelText: '持卡人姓名'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (bankCtrl.text.isEmpty ||
                  cardCtrl.text.isEmpty ||
                  holderCtrl.text.isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              final ok = await context.read<WalletController>().addCard(
                    bankName: bankCtrl.text.trim(),
                    cardNumber: cardCtrl.text.trim(),
                    cardHolder: holderCtrl.text.trim(),
                  );
              if (mounted && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('添加失败，请重试')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(WalletController wallet) {
    if (wallet.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加银行卡')),
      );
      return;
    }

    BankCard selectedCard = wallet.cards.first;
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('提现申请'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('收款卡', isSmall: true),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<BankCard>(
                  value: selectedCard,
                  items: wallet.cards
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                                '${c.bankName} **** ${c.cardNumber}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSt(() => selectedCard = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '提现金额（元）',
                    prefixText: '¥ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final yuan = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (yuan <= 0) return;
                Navigator.pop(ctx);
                final msg = await wallet.withdraw(
                  amount: (yuan * 100).round(),
                  cardID: selectedCard.id,
                );
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('提现结果'),
                    content: Text(msg),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '我的钱包'),
      body: wallet.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              children: [
                // 余额卡片
                _buildBalanceCard(wallet),
                const SizedBox(height: AppSpacing.xl),

                // 银行卡
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText('银行卡', isTitle: true),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加'),
                      onPressed: _showAddCardDialog,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (wallet.cards.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: AppText('暂无绑定银行卡', isSmall: true),
                    ),
                  )
                else
                  ...wallet.cards.map((c) => _buildCardItem(wallet, c)),
                const SizedBox(height: AppSpacing.xl),

                // 提现按钮
                AppButton(
                  label: '申请提现',
                  onPressed: () => _showWithdrawDialog(wallet),
                ),
              ],
            ),
    );
  }

  Widget _buildBalanceCard(WalletController wallet) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppText('可用余额', isSmall: true),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '¥ ${wallet.account?.balanceYuan ?? '0.00'}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (wallet.account != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '货币：${wallet.account!.currency}',
              isSmall: true,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(WalletController wallet, BankCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.cardBackground,
      child: ListTile(
        leading: const Icon(Icons.credit_card, color: AppColors.primary),
        title: AppText(card.bankName),
        subtitle: AppText(
          '**** **** **** ${card.cardNumber}  ${card.cardHolder}',
          isSmall: true,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () async {
            final ok = await wallet.removeCard(card.id);
            if (mounted && !ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('删除失败')),
              );
            }
          },
        ),
      ),
    );
  }
}
