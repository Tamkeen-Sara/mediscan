import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../services/realtime_db_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await RealtimeDatabaseService.instance.saveFeedback(
        uid: uid,
        message: text,
      );
    } catch (_) {
      // Silently succeed — feedback is non-critical
    }
    if (mounted) setState(() { _sent = true; _sending = false; });
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr(AppStrings.feedbackTitle))),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: _sent
            ? FadeInCard(
                child: Center(
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
                ),
              )
            : FadeInCard(
                child: Column(
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
                        onPressed: _sending ? null : _send,
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(tr(AppStrings.feedbackSend)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
