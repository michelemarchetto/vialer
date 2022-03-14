import 'package:sentry_flutter/sentry_flutter.dart';
import '../entities/system_user.dart';

class ErrorTrackingRepository {
  Future<void> run(
    void Function() appRunner,
    String dsn,
    SystemUser? user,
  ) async {
    await SentryFlutter.init(
      (options) => options
        ..dsn = dsn
        ..beforeSend = (event, {hint}) => event.copyWith(
              user: SentryUser(id: user?.uuid),
            ),
      appRunner: appRunner,
    );
  }
}
