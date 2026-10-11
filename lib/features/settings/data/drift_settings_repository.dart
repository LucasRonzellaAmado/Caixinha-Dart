import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/result/result.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  static const settingsKey = 'app_settings';

  final AppDatabase _db;

  @override
  Stream<AppSettings> watch() =>
      (_db.select(_db.settingsEntries)..where((s) => s.key.equals(settingsKey)))
          .watchSingleOrNull()
          .map(_decode);

  @override
  Future<AppSettings> load() async {
    final row = await (_db.select(_db.settingsEntries)
          ..where((s) => s.key.equals(settingsKey)))
        .getSingleOrNull();
    return _decode(row);
  }

  @override
  Future<Result<void>> save(AppSettings settings) => guardDatabase(
        () => _db.into(_db.settingsEntries).insertOnConflictUpdate(
              SettingsEntriesCompanion.insert(
                key: settingsKey,
                value: jsonEncode(settings.toJson()),
              ),
            ),
        message: 'Não foi possível salvar as configurações.',
      );

  AppSettings _decode(SettingRow? row) {
    if (row == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(row.value) as Map<String, dynamic>);
  }
}
