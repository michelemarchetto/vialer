import 'dart:async';

import 'package:meta/meta.dart';

import '../../../dependency_locator.dart';
import '../../repositories/metrics.dart';
import '../../use_case.dart';

class TrackPermissionUseCase extends FutureUseCase<void> {
  final _metricsRepository = dependencyLocator<MetricsRepository>();

  @override
  Future<void> call({
    @required String type,
    @required bool granted,
  }) =>
      _metricsRepository.track(
        'permission',
        {
          'type': type,
          'granted': granted,
        },
      );
}
