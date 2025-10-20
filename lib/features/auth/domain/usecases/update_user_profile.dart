import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parameters for updating user profile
class UpdateUserProfileParams extends Equatable {
  final String? displayName;
  final String? photoUrl;

  const UpdateUserProfileParams({this.displayName, this.photoUrl});

  @override
  List<Object?> get props => [displayName, photoUrl];
}

/// Use case for updating user profile information
class UpdateUserProfile implements UseCase<User, UpdateUserProfileParams> {
  final AuthRepository repository;

  UpdateUserProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserProfileParams params) async {
    return await repository.updateProfile(
      displayName: params.displayName,
      photoUrl: params.photoUrl,
    );
  }
}
