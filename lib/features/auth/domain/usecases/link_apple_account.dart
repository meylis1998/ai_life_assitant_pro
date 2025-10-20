import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for linking Apple account to existing user
class LinkAppleAccount implements UseCase<User, NoParams> {
  final AuthRepository repository;

  LinkAppleAccount(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.linkAppleAccount();
  }
}
