import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';
import '../models/medicine_model.dart';

class SafetyCard extends StatefulWidget {
  final MedicineModel medicine;

  const SafetyCard({super.key, required this.medicine});

  @override
  State<SafetyCard> createState() => _SafetyCardState();
}

class _SafetyCardState extends State<SafetyCard> {
  bool _warningsExpanded = true;
  bool _sideEffectsExpanded = false;
  bool _pregnancyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: AppDimensions.iconSM,
                    color: AppColors.statusRed),
                const SizedBox(width: AppDimensions.spaceSM),
                Text(tr(AppStrings.safetyTitle),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.statusRed,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: AppDimensions.spaceLG),
            _Section(
              label: tr(AppStrings.warningsLabel),
              content: widget.medicine.warningsPlain.isNotEmpty
                  ? widget.medicine.warningsPlain
                  : widget.medicine.warnings.join('\n• '),
              expanded: _warningsExpanded,
              onToggle: () =>
                  setState(() => _warningsExpanded = !_warningsExpanded),
              icon: Icons.warning_amber_outlined,
              color: AppColors.statusAmber,
            ),
            _Section(
              label: tr(AppStrings.sideEffectsLabel),
              content: widget.medicine.sideEffectsPlain.isNotEmpty
                  ? widget.medicine.sideEffectsPlain
                  : widget.medicine.sideEffects.join('\n• '),
              expanded: _sideEffectsExpanded,
              onToggle: () => setState(
                  () => _sideEffectsExpanded = !_sideEffectsExpanded),
              icon: Icons.health_and_safety_outlined,
              color: AppColors.statusRed,
            ),
            _Section(
              label: tr(AppStrings.pregnancyLabel),
              content: widget.medicine.pregnancySafetyPlain,
              expanded: _pregnancyExpanded,
              onToggle: () => setState(
                  () => _pregnancyExpanded = !_pregnancyExpanded),
              icon: Icons.pregnant_woman_outlined,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String content;
  final bool expanded;
  final VoidCallback onToggle;
  final IconData icon;
  final Color color;

  const _Section({
    required this.label,
    required this.content,
    required this.expanded,
    required this.onToggle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
            child: Row(
              children: [
                Icon(icon, size: AppDimensions.iconSM, color: color),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600))),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: AppDimensions.iconSM,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(
                bottom: AppDimensions.spaceSM,
                left: AppDimensions.spaceMD + AppDimensions.iconSM),
            child: Text(content,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: AppDimensions.animNormal),
        ),
      ],
    );
  }
}
