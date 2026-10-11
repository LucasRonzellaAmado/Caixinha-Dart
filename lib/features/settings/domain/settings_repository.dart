import '../../../core/result/result.dart';
import 'app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  Future<AppSettings> load();

  Future<Result<void>> save(AppSettings settings);
}
