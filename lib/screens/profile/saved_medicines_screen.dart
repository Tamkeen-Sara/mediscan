import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/medicine_model.dart';
import '../../providers/scan_provider.dart';
import '../../services/realtime_db_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  List<MedicineModel> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final list = await RealtimeDatabaseService.instance.getSavedMedicines(uid);
    if (mounted) setState(() { _medicines = list; _loading = false; });
  }

  Future<void> _remove(MedicineModel m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await RealtimeDatabaseService.instance.removeSavedMedicine(uid, m.id);
    setState(() => _medicines.removeWhere((x) => x.id == m.id));
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.savedTitle))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: AppDimensions.iconXXL,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(tr(AppStrings.noSaved),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppDimensions.spaceSM),
                      Text(tr(AppStrings.noSavedDesc),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.pagePadding),
                  itemCount: _medicines.length,
                  itemBuilder: (ctx, i) {
                    final m = _medicines[i];
                    return FadeInCard(
                      delay: Duration(milliseconds: 70 * i),
                      padding: EdgeInsets.zero,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
                        child: ListTile(
                          leading: Container(
                            width: AppDimensions.avatarSM * 2,
                            height: AppDimensions.avatarSM * 2,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.infoBlueTintDark
                                  : AppColors.infoBlueTint,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusSM),
                            ),
                            child: const Icon(Icons.medication_outlined,
                                color: AppColors.primaryBlue,
                                size: AppDimensions.iconSM),
                          ),
                          title: Text(m.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: m.genericName.isNotEmpty
                              ? Text(m.genericName)
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.statusRed),
                            onPressed: () => _confirmRemove(ctx, m, tr),
                          ),
                          onTap: () {
                            ctx.read<ScanProvider>().setManualMedicine(m);
                            Navigator.pushNamed(ctx, '/results',
                                arguments: {'isInfoMode': true});
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmRemove(BuildContext ctx, MedicineModel m,
      String Function(String) tr) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(tr(AppStrings.removeSaved)),
        content: Text(tr(AppStrings.removeSavedConfirm)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(AppStrings.cancel))),
          TextButton(
              onPressed: () { Navigator.pop(ctx); _remove(m); },
              child: Text(tr(AppStrings.delete),
                  style: const TextStyle(color: AppColors.statusRed))),
        ],
      ),
    );
  }
}
