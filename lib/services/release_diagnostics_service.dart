import '../data/app_database.dart';
import '../models/backup_snapshot.dart';
import '../models/weekly_case.dart';
import 'backup_service.dart';
import 'cloud_sync_service.dart';

class ReleaseDiagnostics {
  const ReleaseDiagnostics({
    required this.appVersion,
    required this.databaseSchema,
    required this.backupSchema,
    required this.weeklyCaseSchema,
    required this.contentSchemaSummary,
    required this.cloudConfigured,
    required this.weeklyCasesConfigured,
    required this.lastBackupAt,
  });

  final String appVersion;
  final int databaseSchema;
  final int backupSchema;
  final int weeklyCaseSchema;
  final String contentSchemaSummary;
  final bool cloudConfigured;
  final bool weeklyCasesConfigured;
  final DateTime? lastBackupAt;
}

class ReleaseDiagnosticsService {
  const ReleaseDiagnosticsService(
    this._backupService,
    this._cloudConfig,
  );

  final BackupService _backupService;
  final CloudRuntimeConfig _cloudConfig;

  Future<ReleaseDiagnostics> load() async {
    return ReleaseDiagnostics(
      appVersion: BackupService.appVersion,
      databaseSchema: AppDatabase.schemaVersion,
      backupSchema: BackupSnapshot.currentSchemaVersion,
      weeklyCaseSchema: WeeklyCasePack.supportedSchemaVersion,
      contentSchemaSummary:
          'career tasks v3 • capstone v1 • interviews v1 • weekly v1',
      cloudConfigured: _cloudConfig.cloudConfigured,
      weeklyCasesConfigured: _cloudConfig.weeklyCasesConfigured,
      lastBackupAt: await _backupService.lastBackupAt(),
    );
  }
}
