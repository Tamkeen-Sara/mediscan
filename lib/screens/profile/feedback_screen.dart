import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/translation_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    // In a real app, send to Firebase / email. Here we just show confirmation.
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.feedbackTitle))),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: _sent
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: AppDimensions.iconXXL,
                        color: AppColors.statusGreen),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(tr(AppStrings.feedbackSent),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: tr(AppStrings.feedbackHint),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLG,
                    child: ElevatedButton(
                      onPressed: _send,
                      child: Text(tr(AppStrings.feedbackSend)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
