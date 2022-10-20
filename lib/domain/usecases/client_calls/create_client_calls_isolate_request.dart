import 'package:dartx/dartx.dart';

import '../../entities/settings/call_setting.dart';
import '../../entities/user.dart';
import '../../repositories/database/client_calls.dart';
import '../../use_case.dart';
import '../get_logged_in_user.dart';
import '../get_voipgrid_base_url.dart';

class CreateClientCallsIsolateRequestUseCase extends UseCase {
  final _getUser = GetLoggedInUserUseCase();
  final _getBaseUrl = GetVoipgridBaseUrlUseCase();

  List<int> get _usersPhoneAccounts {
    final availability = _getUser().settings.get(
          CallSetting.availability,
        );

    return availability.phoneAccounts
        .filter((phoneAccount) => phoneAccount.id != null)
        .map((phoneAccount) => phoneAccount.id!)
        .toList();
  }

  Future<ClientCallsIsolateRequest> call({
    required Map<DateTime, DateTime> dateRangesToQuery,
  }) async {
    return ClientCallsIsolateRequest(
      user: _getUser(),
      voipgridApiBaseUrl: await _getBaseUrl(),
      databasePath: (await ClientCallsDatabase.databaseFile).path,
      dateRangesToQuery: dateRangesToQuery,
      userPhoneAccountIds: await _usersPhoneAccounts,
    );
  }
}

class ClientCallsIsolateRequest {
  final User user;
  final String voipgridApiBaseUrl;
  final String databasePath;
  final Map<DateTime, DateTime> dateRangesToQuery;
  final List<int> userPhoneAccountIds;

  const ClientCallsIsolateRequest({
    required this.user,
    required this.voipgridApiBaseUrl,
    required this.databasePath,
    required this.dateRangesToQuery,
    required this.userPhoneAccountIds,
  });
}
