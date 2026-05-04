import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/medicine_model.dart';
import '../../providers/scan_provider.dart';
import '../../services/translation_service.dart';

class ManualEditScreen extends StatefulWidget {
  const ManualEditScreen({super.key});

  @override
  State<ManualEditScreen> createState() => _ManualEditScreenState();
}

class _ManualEditScreenState extends State<ManualEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _genericCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _mfrCtrl;

  @override
  void initState() {
    super.initState();
    final med = context.read<ScanProvider>().medicine;
    _nameCtrl = TextEditingController(text: med?.brandName ?? '');
    _genericCtrl = TextEditingController(text: med?.genericName ?? '');
    _dosageCtrl = TextEditingController(text: med?.strength ?? '');
    _mfrCtrl = TextEditingController(text: med?.manufacturer ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _dosageCtrl.dispose();
    _mfrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = context.read<ScanProvider>().medicine;

    final updated = MedicineModel(
      id: existing?.id ?? 'manual_${DateTime.now().millisecondsSinceEpoch}',
      brandName: _nameCtrl.text.trim(),
      genericName: _genericCtrl.text.trim(),
      manufacturer: _mfrCtrl.text.trim(),
      strength: _dosageCtrl.text.trim(),
      // Preserve all other fields if editing existing medicine
      category: existing?.category ?? '',
      dosageForm: existing?.dosageForm ?? '',
      dosageAdults: existing?.dosageAdults ?? '',
      dosageChildren: existing?.dosageChildren ?? '',
      maxDailyDose: existing?.maxDailyDose ?? '',
      onsetTime: existing?.onsetTime ?? '',
      storageInstructions: existing?.storageInstructions ?? '',
      summaryEn: existing?.summaryEn ?? '',
      summaryUr: existing?.summaryUr ?? '',
      symptomsPlain: existing?.symptomsPlain ?? [],
      warningsPlain: existing?.warningsPlain ?? [],
      sideEffectsPlain: existing?.sideEffectsPlain ?? [],
      pregnancySafetyPlain: existing?.pregnancySafetyPlain ?? '',
      importantNote: existing?.importantNote ?? '',
      warnings: existing?.warnings ?? [],
      sideEffects: existing?.sideEffects ?? [],
      contraindications: existing?.contraindications ?? [],
      drugInteractions: existing?.drugInteractions ?? [],
      pregnancyCategory: existing?.pregnancyCategory ?? '',
      searchKeywords: _nameCtrl.text.trim().toLowerCase(),
      aliases: [],
    );

    context.read<ScanProvider>().setManualMedicine(updated);
    Navigator.pushReplacementNamed(context, '/results');
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.editTitle))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          children: [
            _Field(
              controller: _nameCtrl,
              label: tr(AppStrings.nameField),
              required: true,
              tr: tr,
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            _Field(
              controller: _genericCtrl,
              label: tr(AppStrings.genericField),
              tr: tr,
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            _Field(
              controller: _dosageCtrl,
              label: tr(AppStrings.dosageField),
              tr: tr,
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            _Field(
              controller: _mfrCtrl,
              label: tr(AppStrings.manufacturerField),
              tr: tr,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLG,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(tr(AppStrings.save)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final String Function(String) tr;

  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? tr(AppStrings.fieldRequired)
              : null
          : null,
    );
  }
}
