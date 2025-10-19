import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/ai_chat_repository.dart';

/// Use case for getting chat history
class GetChatHistory implements UseCase<Conversation, ChatHistoryParams> {
  final AIChatRepository repository;

  GetChatHistory(this.repository);

  @override
  Future<Either<Failure, Conversation>> call(ChatHistoryParams params) async {
    return await repository.getChatHistory(params.conversationId);
  }
}

/// Parameters for getting chat history
class ChatHistoryParams extends Equatable {
  final String conversationId;

  const ChatHistoryParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}