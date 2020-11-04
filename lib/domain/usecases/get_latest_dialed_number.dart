import '../../dependency_locator.dart';
import '../repositories/storage.dart';
import '../use_case.dart';

class GetLatestDialedNumberUseCase extends UseCase<String> {
  final _storageRepository = dependencyLocator<StorageRepository>();

  @override
  String call() => _storageRepository.lastDialedNumber;
}
