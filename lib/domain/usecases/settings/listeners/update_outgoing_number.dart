import 'dart:async';

import '../../../../app/util/loggable.dart';
import '../../../../dependency_locator.dart';
import '../../../entities/settings/call_setting.dart';
import '../../../entities/user.dart';
import '../../../repositories/metrics.dart';
import '../../../repositories/outgoing_numbers.dart';
import 'setting_change_listener.dart';

class UpdateOutgoingNumberListener extends SettingChangeListener<OutgoingNumber>
    with Loggable {
  final _outgoingNumbersRepository =
      dependencyLocator<OutgoingNumbersRepository>();
  final _metricsRepository = dependencyLocator<MetricsRepository>();

  @override
  final key = CallSetting.outgoingNumber;

  @override
  FutureOr<SettingChangeListenResult> beforeStore(
    User user,
    OutgoingNumber number,
  ) =>
      changeRemoteValue(() async {
        if (!user.canChangeOutgoingNumber) {
          logger.warning('Unable to update outgoing number, no client_uuid');
          return false;
        }

        if (number is SuppressedOutgoingNumber) {
          logger.info('Attempting to suppress the user\'s outgoing number');

          _metricsRepository.track('suppress-outgoing-number');

          return _outgoingNumbersRepository.suppressOutgoingNumber(user: user);
        }

        logger.info('Changing the user\'s outgoing number');

        _metricsRepository.track('change-outgoing-number');

        return _outgoingNumbersRepository.changeOutgoingNumber(
          user: user,
          number: (number as UnsuppressedOutgoingNumber).value,
        );
      });
}
