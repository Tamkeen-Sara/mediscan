import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/offline_ai_banner.dart';
import '../../widgets/scan_context_card.dart';
import '../../widgets/suggested_questions_card.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(BuildContext ctx, [String? quickFact]) {
    if (!mounted) return;
    final text = quickFact ?? _inputCtrl.text.trim();
    if (text.isEmpty) return;
    if (quickFact == null) _inputCtrl.clear();
    final langCode = ctx.read<LanguageProvider>().languageCode;
    final prefs = ctx.read<PreferencesProvider>();
    ctx.read<ChatProvider>().sendMessage(
          text,
          languageCode: langCode,
          useGemini: prefs.useGemini,
          fallbackTemplates: prefs.fallbackTemplates,
        );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: AppDimensions.animNormal),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final chat = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(AppStrings.chatTitle)),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.read<ChatProvider>().clearMessages(),
              tooltip: tr(AppStrings.chatClearHistory),
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineAiBanner(visible: chat.isOffline),

          // Context card + quick-fact chips when a medicine is loaded
          if (chat.hasContext && chat.contextMedicine != null) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            FadeInCard(
              delay: const Duration(milliseconds: 80),
              padding: EdgeInsets.zero,
              child: ScanContextCard(
                medicineName: chat.contextMedicine!.displayName,
                genericName: chat.contextMedicine!.genericName,
                category: chat.contextMedicine!.category,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            FadeInCard(
              delay: const Duration(milliseconds: 140),
              padding: EdgeInsets.zero,
              child: _QuickFactChips(
                isDark: isDark,
                onTap: (q) => _send(context, q),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            // Suggested questions from the scanned medicine
            if (chat.contextMedicine!.cachedSuggestedQuestions?.isNotEmpty ==
                true)
              FadeInCard(
                delay: const Duration(milliseconds: 190),
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  child: SuggestedQuestionsCard(
                    questions: chat.contextMedicine!.cachedSuggestedQuestions!,
                    onQuestionTap: (q) => _send(context, q),
                  ),
                ),
              ),
          ],

          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyState(
                    hasContext: chat.hasContext,
                    isDark: isDark,
                    onCheckSymptoms: () =>
                        Navigator.pushNamed(context, '/symptom-checker'),
                    onQuestionTap: (q) => _send(context, q),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(AppDimensions.pagePadding),
                    itemCount:
                        chat.messages.length + (chat.isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (chat.isTyping && i == chat.messages.length) {
                        return const Padding(
                          padding:
                              EdgeInsets.only(bottom: AppDimensions.spaceSM),
                          child: TypingIndicator(),
                        );
                      }
                      final msg = chat.messages[i];
                      if (msg.isLoading) return const SizedBox.shrink();
                      return FadeInCard(
                        delay: Duration(milliseconds: 50 * i),
                        padding: const EdgeInsets.only(
                            bottom: AppDimensions.spaceSM),
                        child: ChatBubble(message: msg),
                      );
                    },
                  ),
          ),

          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding,
                  vertical: AppDimensions.spaceSM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      decoration: InputDecoration(
                        hintText: tr(AppStrings.chatTypeHint),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMD,
                            vertical: AppDimensions.spaceSM),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                  IconButton.filled(
                    onPressed: () => _send(context),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-fact chips ──────────────────────────────────────────────────────────

class _QuickFactChips extends StatelessWidget {
  final bool isDark;
  final void Function(String) onTap;

  const _QuickFactChips({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final chips = [
      (Icons.medication_outlined, tr(AppStrings.shortcutDosage)),
      (Icons.warning_amber_outlined, tr(AppStrings.shortcutSideEffects)),
      (Icons.sync_alt_outlined, tr(AppStrings.shortcutInteractions)),
      (Icons.pregnant_woman_outlined, tr(AppStrings.shortcutPregnancy)),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spaceSM),
        itemBuilder: (_, i) {
          final (icon, label) = chips[i];
          return ActionChip(
            avatar: Icon(icon, size: 16, color: AppColors.primaryBlue),
            label: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primaryBlue)),
            side: const BorderSide(color: AppColors.primaryBlue),
            backgroundColor:
                isDark ? AppColors.infoBlueTintDark : AppColors.infoBlueTint,
            onPressed: () => onTap(label),
          );
        },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasContext;
  final bool isDark;
  final VoidCallback onCheckSymptoms;
  final void Function(String) onQuestionTap;

  const _EmptyState({
    required this.hasContext,
    required this.isDark,
    required this.onCheckSymptoms,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;

    if (hasContext) {
      return Center(
        child: Text(
          tr(AppStrings.chatNoMessages),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textHintDark
                    : AppColors.textHintLight,
              ),
        ),
      );
    }

    // General mode — AI assistant prompt + Check Symptoms CTA
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: AppDimensions.iconXXL,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            tr(AppStrings.chatNoMessages),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceMD),

          // 4 spec quick-question chips for general mode
          ...const [
            'What is Panadol used for?',
            'Is it safe to take antibiotics without a prescription?',
            'What should I do if I took too many tablets?',
            'How do I know if a medicine has expired?',
          ].map((q) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXS),
                child: InkWell(
                  onTap: () => onQuestionTap(q),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceMD,
                        vertical: AppDimensions.spaceSM),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.infoBlueTintDark
                          : AppColors.infoBlueTint,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                      border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.primaryBlue),
                        const SizedBox(width: AppDimensions.spaceXS),
                        Expanded(
                          child: Text(q,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.primaryBlue)),
                        ),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: AppDimensions.spaceMD),

          // Check Symptoms shortcut card
          InkWell(
            onTap: onCheckSymptoms,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.chipGreenTintDark
                    : AppColors.chipGreenTint,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(
                    color: AppColors.chipGreen.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceSM),
                    decoration: BoxDecoration(
                      color: AppColors.chipGreen,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        color: AppColors.white, size: AppDimensions.iconMD),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(AppStrings.chatCheckSymptoms),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: AppColors.chipGreen,
                                  fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(AppStrings.checkerDesc),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.chipGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
