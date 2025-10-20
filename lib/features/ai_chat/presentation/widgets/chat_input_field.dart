import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSubmit(String value) {
    if (value.trim().isNotEmpty && widget.isEnabled) {
      widget.onSend();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: widget.isEnabled
                  ? () {
                      // TODO: Implement file attachment
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File attachment coming soon!'),
                        ),
                      );
                    }
                  : null,
              tooltip: 'Attach file',
            ),

            // Input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSubmit,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  // Allow Shift+Enter for new line
                  onChanged: (text) {
                    // Handle text change
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Voice input button
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: widget.isEnabled
                  ? () {
                      // TODO: Implement voice input
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice input coming soon!'),
                        ),
                      );
                    }
                  : null,
              tooltip: 'Voice input',
            ),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _hasText && widget.isEnabled
                      ? AppTheme.primaryColor
                      : theme.disabledColor,
                ),
                onPressed: _hasText && widget.isEnabled ? widget.onSend : null,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
