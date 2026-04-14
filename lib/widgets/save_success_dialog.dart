import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/translation_service.dart';
import '../constants/app_strings.dart';

class SaveSuccessDialog extends StatefulWidget {
  final VoidCallback? onViewSaved;
  final VoidCallback? onDone;

  const SaveSuccessDialog({super.key, this.onViewSaved, this.onDone});

  static Future<void> show(BuildContext context,
      {VoidCallback? onViewSaved, VoidCallback? onDone}) {
    return showDialog(
      context: context,
      builder: (_) =>
          SaveSuccessDialog(onViewSaved: onViewSaved, onDone: onDone),
    );
  }

  @override
  State<SaveSuccessDialog> createState() => _SaveSuccessDialogState();
}

class _SaveSuccessDialogState extends State<SaveSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(
            milliseconds: AppDimensions.animSlow));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sectionPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: AppDimensions.iconXXL,
                height: AppDimensions.iconXXL,
                decoration: const BoxDecoration(
                  color: AppColors.statusGreenTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: AppDimensions.iconLG,
                    color: AppColors.statusGreen),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Text(tr(AppStrings.savedSuccess),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceLG),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDone?.call();
                    },
                    child: Text(tr(AppStrings.done)),
                  ),
                ),
                if (widget.onViewSaved != null) ...[
                  const SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onViewSaved?.call();
                      },
                      child: Text(tr(AppStrings.savedTitle)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
