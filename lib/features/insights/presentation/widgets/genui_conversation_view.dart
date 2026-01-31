import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

typedef UserPromptBuilder =
    Widget Function(BuildContext context, UserMessage message);
typedef UserUiInteractionBuilder =
    Widget Function(BuildContext context, UserUiInteractionMessage message);

class GenUIConversationView extends StatelessWidget {
  const GenUIConversationView({
    super.key,
    required this.messages,
    required this.manager,
    this.userPromptBuilder,
    this.userUiInteractionBuilder,
    this.showInternalMessages = false,
  });

  final List<ChatMessage> messages;
  final A2uiMessageProcessor manager;
  final UserPromptBuilder? userPromptBuilder;
  final UserUiInteractionBuilder? userUiInteractionBuilder;
  final bool showInternalMessages;

  @override
  Widget build(BuildContext context) {
    final List<ChatMessage> renderedMessages = messages.where((message) {
      if (showInternalMessages) return true;
      return message is! InternalMessage && message is! ToolResponseMessage;
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: renderedMessages.length,
      itemBuilder: (context, index) {
        final ChatMessage message = renderedMessages[index];
        switch (message) {
          case UserMessage():
            return userPromptBuilder != null
                ? userPromptBuilder!(context, message)
                : const SizedBox.shrink(); // Hide user prompts for silent AI
          case AiTextMessage():
            final String text = message.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('\n');
            if (text.trim().isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(text, style: const TextStyle(color: Colors.white70)),
            );
          case AiUiMessage():
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: GenUiSurface(
                key: message.uiKey,
                host: manager,
                surfaceId: message.surfaceId,
              ),
            );
          case InternalMessage():
            return const SizedBox.shrink();
          case UserUiInteractionMessage():
            return userUiInteractionBuilder != null
                ? userUiInteractionBuilder!(context, message)
                : const SizedBox.shrink();
          case ToolResponseMessage():
            return const SizedBox.shrink();
        }
      },
    );
  }
}
