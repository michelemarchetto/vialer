import 'package:flutter/material.dart';

import '../abstract/controller.dart';
import '../../../../resources/theme.dart';
import '../../../../../device/repositories/permission.dart';
import '../../../../../domain/entities/onboarding/permission.dart';

import '../abstract/page.dart';

class CallPermissionPage extends StatelessWidget {
  final VoidCallback forward;

  const CallPermissionPage(this.forward, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionPage(
      controller: PermissionController(
        Permission.phone,
        DevicePermissionRepository(),
        forward,
      ),
      icon: Icon(VialerSans.phone),
      title: Text(
        'Call permission',
        textAlign: TextAlign.center,
      ),
      description: Text(
        'This permissions is required to make calls seamlessly from'
        'the app using the default call app.',
      ),
    );
  }
}
