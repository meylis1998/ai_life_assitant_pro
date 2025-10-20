import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/usage_repository.dart';

/// Parameters for incrementing usage
class IncrementUsageParams extends Equatable {
  final String userId;
  final int messageCount;
  final int tokenCount;
  final String provider;

  const IncrementUsageParams({
    required this.userId,
    this.messageCount = 1,
    required this.tokenCount,
    required this.provider,
  });

  @override
  List<Object?> get props => [userId, messageCount, tokenCount, provider];
}

/// Use case for incrementing user's usage counters
class IncrementUsage implements UseCase<void, IncrementUsageParams> {
  final UsageRepository repository;

  IncrementUsage(this.repository);

  @override
  Future<Either<Failure, void>> call(IncrementUsageParams params) async {
    return await repository.incrementUsage(
      userId: params.userId,
      messageCount: params.messageCount,
      tokenCount: params.tokenCount,
      provider: params.provider,
    );
  }
}
