import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/ai_chat_repository.dart';

/// Use case for sending a message and getting a response
class SendMessage implements UseCase<ChatMessage, MessageParams> {
  final AIChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(MessageParams params) async {
    return await repository.sendMessage(
      message: params.message,
      provider: params.provider,
      conversationId: params.conversationId,
      context: params.context,
    );
  }
}

/// Parameters for sending a message
class MessageParams extends Equatable {
  final String message;
  final AIProvider provider;
  final String? conversationId;
  final Map<String, dynamic>? context;

  const MessageParams({
    required this.message,
    required this.provider,
    this.conversationId,
    this.context,
  });

  @override
  List<Object?> get props => [message, provider, conversationId, context];
}
