import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/usage_repository.dart';

/// Parameters for checking user quota
class CheckUserQuotaParams extends Equatable {
  final String userId;
  final String provider;
  final int estimatedTokens;

  const CheckUserQuotaParams({
    required this.userId,
    required this.provider,
    this.estimatedTokens = 500,
  });

  @override
  List<Object?> get props => [userId, provider, estimatedTokens];
}

/// Use case for checking if user has available quota
class CheckUserQuota implements UseCase<bool, CheckUserQuotaParams> {
  final UsageRepository repository;

  CheckUserQuota(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckUserQuotaParams params) async {
    return await repository.checkQuota(
      userId: params.userId,
      provider: params.provider,
      estimatedTokens: params.estimatedTokens,
    );
  }
}
