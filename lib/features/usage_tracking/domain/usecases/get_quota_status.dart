import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/quota_status.dart';
import '../repositories/usage_repository.dart';

/// Parameters for getting quota status
class GetQuotaStatusParams {
  final String userId;

  const GetQuotaStatusParams({required this.userId});
}

/// Use case for getting user's current quota status
class GetQuotaStatus implements UseCase<QuotaStatus, GetQuotaStatusParams> {
  final UsageRepository repository;

  GetQuotaStatus(this.repository);

  @override
  Future<Either<Failure, QuotaStatus>> call(GetQuotaStatusParams params) async {
    return await repository.getQuotaStatus(params.userId);
  }
}
