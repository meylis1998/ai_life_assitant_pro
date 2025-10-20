import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/usage_repository.dart';

/// Use case to check if user has quota available
class CheckQuota extends UseCase<bool, CheckQuotaParams> {
  final UsageRepository repository;

  CheckQuota(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckQuotaParams params) async {
    return await repository.checkQuota(
      userId: params.userId,
      provider: params.provider,
      estimatedTokens: params.estimatedTokens,
    );
  }
}

/// Parameters for checking quota
class CheckQuotaParams {
  final String userId;
  final String provider;
  final int estimatedTokens;

  CheckQuotaParams({
    required this.userId,
    required this.provider,
    required this.estimatedTokens,
  });
}
