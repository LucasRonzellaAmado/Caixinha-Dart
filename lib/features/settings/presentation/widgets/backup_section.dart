import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../reports/presentation/report_providers.dart';
import '../../domain/app_settings.dart';
import '../settings_providers.dart';

class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  Future<void> _run(Future<Failure?> Function() action, String success) async {
    setState(() => _busy = true);
    final failure = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      showFailure(context, failure);
    } else {
      showMessage(context, success);
    }
  }

  Future<void> _exportFile() => _run(() async {
        final backup = ref.read(backupServiceProvider);
        final json = backup.encode(await backup.export());
        final now = DateTime.now();
        final name = 'caixinha-backup-${Dates.competenceKey(now)}-${now.day}.json';
        final result =
            await ref.read(reportExporterProvider).shareText(name, json);
        return result.failureOrNull;
      }, 'Backup gerado!');

  Future<bool> _confirmRestore() => confirm(
        context,
        title: 'Restaurar backup?',
        message: 'Todos os dados atuais deste aparelho serão substituídos '
            'pelos dados do backup.',
        confirmLabel: 'Restaurar',
        destructive: true,
      );

  Future<void> _importFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null || !mounted) return;
    if (!await _confirmRestore()) return;
    await _run(() async {
      final result = await ref
          .read(backupServiceProvider)
          .restoreFromJson(utf8.decode(bytes));
      return result.failureOrNull;
    }, 'Backup restaurado!');
  }

  Future<void> _upload() => _run(() async {
        final settings = widget.settings;
        final result = await ref.read(syncServiceProvider).upload(
              baseUrl: settings.syncUrl,
              token: settings.syncToken,
            );
        return switch (result) {
          Ok(:final value) => (await ref
                  .read(settingsControllerProvider)
                  .update((current) => current.copyWith(lastSyncAt: value)))
              .failureOrNull,
          Err(:final failure) => failure,
        };
      }, 'Backup enviado para o servidor!');

  Future<void> _download() async {
    if (!await _confirmRestore()) return;
    await _run(() async {
      final settings = widget.settings;
      final result = await ref.read(syncServiceProvider).download(
            baseUrl: settings.syncUrl,
            token: settings.syncToken,
          );
      return result.failureOrNull;
    }, 'Dados restaurados do servidor!');
  }

  Future<void> _editServer() async {
    final url = await askText(
      context,
      title: 'Endereço do servidor',
      initialValue: widget.settings.syncUrl,
      hint: 'https://caixinha.meuhomelab.com',
      keyboardType: TextInputType.url,
      helper: 'Use HTTPS. O app envia e busca o backup em /v1/backup.',
    );
    if (url == null || !mounted) return;
    final token = await askText(
      context,
      title: 'Token de acesso',
      initialValue: widget.settings.syncToken,
      obscure: true,
    );
    if (token == null || !mounted) return;
    final result = await ref.read(settingsControllerProvider).update(
          (current) => current.copyWith(syncUrl: url, syncToken: token),
        );
    if (!mounted) return;
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final lastSync = settings.lastSyncAt;
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Exportar backup'),
          subtitle: const Text('Gera um arquivo para guardar onde quiser.'),
          enabled: !_busy,
          onTap: _exportFile,
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Importar backup'),
          subtitle: const Text('Substitui os dados por um arquivo de backup.'),
          enabled: !_busy,
          onTap: _importFile,
        ),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: const Text('Servidor de backup'),
          subtitle: Text(
            settings.syncUrl.isEmpty ? 'Não configurado' : settings.syncUrl,
          ),
          enabled: !_busy,
          onTap: _editServer,
        ),
        if (settings.hasSyncConfig) ...[
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Enviar backup agora'),
            subtitle: Text(
              lastSync == null
                  ? 'Nunca enviado'
                  : 'Último envio: ${Dates.day(lastSync)}',
            ),
            enabled: !_busy,
            onTap: _upload,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restaurar do servidor'),
            enabled: !_busy,
            onTap: _download,
          ),
        ],
      ],
    );
  }
}
