import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/offline_ai_banner.dart';

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

  void _send(BuildContext ctx) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final langCode = ctx.read<LanguageProvider>().languageCode;
    ctx.read<ChatProvider>().sendMessage(text, languageCode: langCode);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Text(
                      tr(AppStrings.chatNoMessages),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textHintLight,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.all(AppDimensions.pagePadding),
                    itemCount:
                        chat.messages.length + (chat.isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (chat.isTyping && i == chat.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(
                              bottom: AppDimensions.spaceSM),
                          child: TypingIndicator(),
                        );
                      }
                      final msg = chat.messages[i];
                      if (msg.isLoading) return const SizedBox.shrink();
                      return Padding(
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
