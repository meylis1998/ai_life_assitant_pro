import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/ai_chat_repository.dart';

/// Use case for streaming a response
class StreamResponse implements StreamUseCase<String, StreamMessageParams> {
  final AIChatRepository repository;

  StreamResponse(this.repository);

  @override
  Stream<Either<Failure, String>> call(StreamMessageParams params) {
    return repository.streamResponse(
      message: params.message,
      provider: params.provider,
      conversationId: params.conversationId,
      context: params.context,
    );
  }
}

/// Parameters for streaming a message response
class StreamMessageParams extends Equatable {
  final String message;
  final AIProvider provider;
  final String? conversationId;
  final Map<String, dynamic>? context;

  const StreamMessageParams({
    required this.message,
    required this.provider,
    this.conversationId,
    this.context,
  });

  @override
  List<Object?> get props => [message, provider, conversationId, context];
}