import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/ai_provider_selector.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _chatBloc = sl<ChatBloc>();

    // Start a new conversation
    _chatBloc.add(const StartNewConversationEvent(
      title: 'New Chat',
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    _chatBloc.add(StreamMessageEvent(
      message: message,
      provider: _chatBloc.state.currentProvider,
      conversationId: _chatBloc.state.conversation?.id,
    ));

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _chatBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            // Provider selector
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return AIProviderSelector(
                  currentProvider: state.currentProvider,
                  onProviderChanged: (provider) {
                    context.read<ChatBloc>().add(
                      SwitchProviderEvent(provider: provider),
                    );
                  },
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.5);
              },
            ),

            // Messages list
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is MessageSent || state is ResponseReceived) {
                    _scrollToBottom();
                  }

                  if (state is ChatError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: AppTheme.errorColor,
                        action: SnackBarAction(
                          label: 'Retry',
                          textColor: Colors.white,
                          onPressed: () {
                            if (state.failedMessage != null) {
                              context.read<ChatBloc>().add(
                                RetryMessageEvent(message: state.failedMessage!),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading && state.conversation == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final messages = state.conversation?.messages ?? [];

                  if (messages.isEmpty && !state.isStreaming) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: messages.length + (state.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        final message = messages[index];
                        return MessageBubble(
                          message: message,
                          onDelete: () {
                            context.read<ChatBloc>().add(
                              DeleteMessageEvent(messageId: message.id),
                            );
                          },
                        ).animate()
                            .fadeIn(duration: 300.ms)
                            .slideX(
                              begin: message.role == MessageRole.user ? 0.2 : -0.2,
                            );
                      } else {
                        // Streaming indicator
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 8,
                              right: 60,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const TypingIndicator(),
                          ),
                        ).animate()
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: -0.2);
                      }
                    },
                  );
                },
              ),
            ),

            // Input field
            ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
              isEnabled: true,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          return Text(
            state.conversation?.title ?? 'AI Life Assistant',
            style: Theme.of(context).textTheme.titleLarge,
          );
        },
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'New Chat',
          onPressed: () {
            context.read<ChatBloc>().add(
              const StartNewConversationEvent(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear_all),
          tooltip: 'Clear Chat',
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Clear Conversation'),
                content: const Text(
                  'Are you sure you want to clear this conversation? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<ChatBloc>().add(
                        const ClearConversationEvent(),
                      );
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).disabledColor,
          ).animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Ask me anything! I\'m here to help.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip(
                context,
                'Tell me a joke',
                Icons.emoji_emotions,
              ),
              _buildSuggestionChip(
                context,
                'Help me code',
                Icons.code,
              ),
              _buildSuggestionChip(
                context,
                'Plan my day',
                Icons.calendar_today,
              ),
              _buildSuggestionChip(
                context,
                'Explain something',
                Icons.lightbulb,
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        _messageController.text = label;
        _sendMessage();
      },
    ).animate()
        .scale(
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }
}