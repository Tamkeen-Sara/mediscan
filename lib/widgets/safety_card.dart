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
    final med = widget.medicine;

    final warnings = med.warningsPlain.isNotEmpty
        ? med.warningsPlain
        : med.warnings;
    final sideEffects = med.sideEffectsPlain.isNotEmpty
        ? med.sideEffectsPlain
        : med.sideEffects;

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
            _BulletSection(
              label: tr(AppStrings.warningsLabel),
              items: warnings,
              expanded: _warningsExpanded,
              onToggle: () =>
                  setState(() => _warningsExpanded = !_warningsExpanded),
              icon: Icons.warning_amber_outlined,
              color: AppColors.statusAmber,
            ),
            _BulletSection(
              label: tr(AppStrings.sideEffectsLabel),
              items: sideEffects,
              expanded: _sideEffectsExpanded,
              onToggle: () =>
                  setState(() => _sideEffectsExpanded = !_sideEffectsExpanded),
              icon: Icons.health_and_safety_outlined,
              color: AppColors.statusRed,
            ),
            if (med.pregnancySafetyPlain.isNotEmpty)
              _TextSection(
                label: tr(AppStrings.pregnancyLabel),
                content: med.pregnancySafetyPlain,
                expanded: _pregnancyExpanded,
                onToggle: () =>
                    setState(() => _pregnancyExpanded = !_pregnancyExpanded),
                icon: Icons.pregnant_woman_outlined,
                color: AppColors.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bullet list section ───────────────────────────────────────────────────────

class _BulletSection extends StatelessWidget {
  final String label;
  final List<String> items;
  final bool expanded;
  final VoidCallback onToggle;
  final IconData icon;
  final Color color;

  const _BulletSection({
    required this.label,
    required this.items,
    required this.expanded,
    required this.onToggle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _Header(
            label: label,
            icon: icon,
            color: color,
            expanded: expanded,
            onToggle: onToggle),
        AnimatedSize(
          duration: const Duration(milliseconds: AppDimensions.animNormal),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppDimensions.spaceSM,
                      left: AppDimensions.spaceMD + AppDimensions.iconSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppDimensions.spaceXXS),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: color)),
                                  Expanded(
                                    child: Text(item,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Plain text section (pregnancy info) ─────────────────────────────────────

class _TextSection extends StatelessWidget {
  final String label;
  final String content;
  final bool expanded;
  final VoidCallback onToggle;
  final IconData icon;
  final Color color;

  const _TextSection({
    required this.label,
    required this.content,
    required this.expanded,
    required this.onToggle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
            label: label,
            icon: icon,
            color: color,
            expanded: expanded,
            onToggle: onToggle),
        AnimatedSize(
          duration: const Duration(milliseconds: AppDimensions.animNormal),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppDimensions.spaceSM,
                      left: AppDimensions.spaceMD + AppDimensions.iconSM),
                  child: Text(content,
                      style: Theme.of(context).textTheme.bodySmall),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Shared expandable header ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;

  const _Header({
    required this.label,
    required this.icon,
    required this.color,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSM, color: color),
            const SizedBox(width: AppDimensions.spaceSM),
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: AppDimensions.iconSM,
            ),
          ],
        ),
      ),
    );
  }
}
