import 'dart:async';

import '../../dependency_locator.dart';
import '../use_case.dart';
import '../user/get_logged_in_user.dart';
import 'authentication_repository.dart';

class ChangePasswordUseCase extends UseCase {
  final _authRepository = dependencyLocator<AuthRepository>();
  final _getUser = GetLoggedInUserUseCase();

  Future<void> call({
    required String currentPassword,
    required String newPassword,
    String? email,
  }) async {
    email ??= _getUser().email;

    await _authRepository.changePassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
