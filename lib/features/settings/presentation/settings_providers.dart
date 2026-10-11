import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/database/database_provider.dart';
import '../../../core/result/result.dart';
import '../data/backup_service.dart';
import '../data/drift_settings_repository.dart';
import '../data/sync_service.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider).value?.themeMode;
  return switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system || null => ThemeMode.system,
  };
});

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(httpClientProvider),
    ref.watch(backupServiceProvider),
  ),
);

class SettingsController {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> update(
    AppSettings Function(AppSettings current) change,
  ) async {
    final AppSettings current;
    try {
      current = await _repository.load();
    } on Object catch (error, stackTrace) {
      return Err(
        DatabaseFailure(
          'Não foi possível ler as configurações.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    return _repository.save(change(current));
  }
}
