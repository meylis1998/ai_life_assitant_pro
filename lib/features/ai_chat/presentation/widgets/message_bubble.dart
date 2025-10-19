import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Provider label for assistant messages
            if (!isUser && message.provider != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4, left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getProviderColor(message.provider!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.provider!.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Message bubble
            Material(
              color: Colors.transparent,
              child: InkWell(
                onLongPress: () => _showMessageOptions(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryColor
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(context, isUser),
                ),
              ),
            ),

            // Timestamp and status
            Container(
              margin: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatter.formatTime(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                  if (message.status == MessageStatus.failed) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppTheme.errorColor,
                    ),
                  ],
                  if (message.status == MessageStatus.sending) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.textTheme.bodySmall?.color?.withOpacity(0.5) ??
                              Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    final theme = Theme.of(context);

    if (message.content.contains('```') ||
        message.content.contains('**') ||
        message.content.contains('##')) {
      // Render as markdown if it contains markdown syntax
      return MarkdownBody(
        data: message.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
          code: TextStyle(
            backgroundColor: isUser
                ? Colors.white.withOpacity(0.2)
                : theme.colorScheme.surface,
            color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: isUser
                ? Colors.white.withOpacity(0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          h1: TextStyle(
            color: isUser ? Colors.white : theme.textTheme.headlineLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: isUser ? Colors.white : theme.textTheme.headlineMedium?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          h3: TextStyle(
            color: isUser ? Colors.white : theme.textTheme.headlineSmall?.color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SelectableText(
      message.content,
      style: TextStyle(
        color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
        fontSize: 14,
      ),
    );
  }

  Color _getProviderColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.gemini:
        return AppTheme.geminiColor;
      case AIProvider.claude:
        return AppTheme.claudeColor;
      case AIProvider.openai:
        return AppTheme.openAIColor;
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(bottomSheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: AppTheme.errorColor,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}