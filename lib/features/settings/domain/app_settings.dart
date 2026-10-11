import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/fiscal/fiscal_rules.dart';
import '../../pix/domain/pix_key.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum AppThemeMode { system, light, dark }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.system => 'Automático',
        AppThemeMode.light => 'Claro',
        AppThemeMode.dark => 'Escuro',
      };
}

@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(false) bool onboardingCompleted,
    @Default('') String businessName,
    @Default('') String ownerName,
    @Default(PixKeyType.cpf) PixKeyType pixKeyType,
    @Default('') String pixKey,
    @Default('') String pixMerchantName,
    @Default('') String pixCity,
    @Default(FiscalDefaults.meiAnnualLimitCents) int meiAnnualLimitCents,
    DateTime? meiOpeningDate,
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(true) bool remindersEnabled,
    @Default(FiscalDefaults.reminderDaysBefore) int reminderDaysBefore,
    @Default('') String syncUrl,
    @Default('') String syncToken,
    DateTime? lastSyncAt,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  bool get hasPixKey => pixKey.trim().isNotEmpty;

  String get pixReceiverName =>
      pixMerchantName.trim().isNotEmpty ? pixMerchantName : businessName;

  bool get hasSyncConfig =>
      syncUrl.trim().isNotEmpty && syncToken.trim().isNotEmpty;
}
