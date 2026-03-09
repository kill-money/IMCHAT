import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';

class MobileContactsPage extends StatelessWidget {
  const MobileContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(
        title: '通讯录',
        showBack: false,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts, size: 64, color: AppColors.textSecondary),
            SizedBox(height: AppSpacing.md),
            AppText(
              '通讯录',
              isSmall: true,
            ),
          ],
        ),
      ),
    );
  }
}

