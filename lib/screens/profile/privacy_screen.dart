import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/realtime_db_service.dart';
import '../../services/translation_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.privacyTitle))),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              child: Text(tr(AppStrings.privacyDataUsage)),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined,
                color: AppColors.statusRed),
            title: Text(tr(AppStrings.privacyDeleteAllData)),
            onTap: () => _confirmDeleteData(context, tr),
          ),
          ListTile(
            leading:
                const Icon(Icons.person_remove_outlined, color: AppColors.statusRed),
            title: Text(tr(AppStrings.privacyDeleteAccount)),
            onTap: () => _confirmDeleteAccount(context, tr),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData(BuildContext ctx, String Function(String) tr) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(tr(AppStrings.privacyDeleteAllData)),
        content: Text(tr(AppStrings.privacyDeleteAllDataConfirm)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(AppStrings.cancel))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await RealtimeDatabaseService.instance
                    .deleteUserData(uid);
              }
            },
            child: Text(tr(AppStrings.delete),
                style: const TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext ctx, String Function(String) tr) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(tr(AppStrings.privacyDeleteAccount)),
        content: Text(tr(AppStrings.privacyDeleteAccountConfirm)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(AppStrings.cancel))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await RealtimeDatabaseService.instance
                    .deleteUserData(user.uid);
                await user.delete();
              }
              if (ctx.mounted) {
                Navigator.popUntil(ctx, (r) => r.isFirst);
              }
            },
            child: Text(tr(AppStrings.delete),
                style: const TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
  }
}
