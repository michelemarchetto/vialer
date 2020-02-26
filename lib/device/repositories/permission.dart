import 'package:permission_handler/permission_handler.dart';

import '../mappers/permission_status.dart';

import '../../domain/entities/onboarding/permission.dart' as domain;
import '../../domain/entities/onboarding/permission_status.dart' as domain;
import '../../domain/repositories/permission.dart';
import '../mappers/permission.dart';

class DevicePermissionRepository extends PermissionRepository {
  @override
  Future<domain.PermissionStatus> getPermissionStatus(
    domain.Permission permission,
  ) async {
    final callPermissionStatus =
        await PermissionHandler().checkPermissionStatus(
      mapDomainPermissionToPermissionGroup(permission),
    );

    return mapPermissionStatusToDomainPermissionStatus(callPermissionStatus);
  }

  @override
  Future<bool> enablePermission(domain.Permission permission) async {
    final group = mapDomainPermissionToPermissionGroup(permission);
    final permissions = await PermissionHandler().requestPermissions([group]);

    final status = permissions[group];

    if (status == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }
}
