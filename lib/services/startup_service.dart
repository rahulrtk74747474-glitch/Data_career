import '../data/app_database.dart';
import 'content_pack_loader.dart';

abstract interface class StartupService {
  Future<void> initialize();
}

class OfflineStartupService implements StartupService {
  const OfflineStartupService(
    this._database,
    this._contentPackLoader,
  );

  final AppDatabase _database;
  final ContentPackLoader _contentPackLoader;

  @override
  Future<void> initialize() async {
    await _database.database;
    await _contentPackLoader.installBundledPacks();
  }
}
