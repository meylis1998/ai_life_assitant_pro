import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_usage_log.dart';
import '../repositories/usage_repository.dart';

/// Use case for logging message usage after API response
class LogMessageUsage implements UseCase<void, MessageUsageLog> {
  final UsageRepository repository;

  LogMessageUsage(this.repository);

  @override
  Future<Either<Failure, void>> call(MessageUsageLog params) async {
    return await repository.logMessageUsage(params);
  }
}
