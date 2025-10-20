import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_usage_stats.dart';
import '../repositories/usage_repository.dart';

/// Use case to get user's usage statistics
class GetUserUsageStats
    extends UseCase<UserUsageStats, GetUserUsageStatsParams> {
  final UsageRepository repository;

  GetUserUsageStats(this.repository);

  @override
  Future<Either<Failure, UserUsageStats>> call(
    GetUserUsageStatsParams params,
  ) async {
    return await repository.getUserStats(params.userId);
  }
}

/// Parameters for getting user usage stats
class GetUserUsageStatsParams {
  final String userId;

  GetUserUsageStatsParams({required this.userId});
}
