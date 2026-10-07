import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
import 'package:dataquest_analyst_career/services/startup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline startup opens SQLite and installs bundled content', () async {
    sqfliteFfiInit();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    final loader = _RecordingContentPackLoader(database);
    final startup = OfflineStartupService(database, loader);

    await startup.initialize();

    final db = await database.database;
    final schema = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'content_packs'",
    );

    expect(schema, hasLength(1));
    expect(loader.installCalls, 1);

    await database.close();
  });
}

class _RecordingContentPackLoader extends ContentPackLoader {
  _RecordingContentPackLoader(super.database);

  int installCalls = 0;

  @override
  Future<List<PackInstallResult>> installBundledPacks() async {
    installCalls++;
    return const [
      PackInstallResult(
        packId: 'startup-test',
        installed: false,
        contentVersion: 1,
      ),
    ];
  }
}
