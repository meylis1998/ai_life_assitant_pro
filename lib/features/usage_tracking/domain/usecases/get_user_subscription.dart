import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_subscription.dart';
import '../repositories/usage_repository.dart';

/// Use case to get user's subscription details
class GetUserSubscription
    extends UseCase<UserSubscription, GetUserSubscriptionParams> {
  final UsageRepository repository;

  GetUserSubscription(this.repository);

  @override
  Future<Either<Failure, UserSubscription>> call(
    GetUserSubscriptionParams params,
  ) async {
    return await repository.getUserSubscription(params.userId);
  }
}

/// Parameters for getting user subscription
class GetUserSubscriptionParams {
  final String userId;

  GetUserSubscriptionParams({required this.userId});
}
