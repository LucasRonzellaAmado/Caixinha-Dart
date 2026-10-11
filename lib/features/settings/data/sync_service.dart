import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/result/result.dart';
import 'backup_service.dart';

class SyncService {
  SyncService(this._client, this._backup);

  static const _timeout = Duration(seconds: 30);

  final http.Client _client;
  final BackupService _backup;

  Future<Result<DateTime>> upload({
    required String baseUrl,
    required String token,
  }) async {
    final uri = endpoint(baseUrl);
    if (uri == null) {
      return const Err(ValidationFailure('Endereço do servidor inválido.'));
    }
    try {
      final body = jsonEncode(await _backup.export());
      final response = await _client
          .put(uri, headers: _headers(token), body: body)
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Ok(DateTime.now());
      }
      return Err(_httpFailure(response.statusCode));
    } on Object catch (error, stackTrace) {
      return Err(
        NetworkFailure(
          'Não consegui falar com o servidor de backup.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> download({
    required String baseUrl,
    required String token,
  }) async {
    final uri = endpoint(baseUrl);
    if (uri == null) {
      return const Err(ValidationFailure('Endereço do servidor inválido.'));
    }
    final http.Response response;
    try {
      response =
          await _client.get(uri, headers: _headers(token)).timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Err(
        NetworkFailure(
          'Não consegui falar com o servidor de backup.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    if (response.statusCode == 404) {
      return const Err(NotFoundFailure('Ainda não existe backup no servidor.'));
    }
    if (response.statusCode != 200) {
      return Err(_httpFailure(response.statusCode));
    }
    return _backup.restoreFromJson(utf8.decode(response.bodyBytes));
  }

  static Uri? endpoint(String baseUrl) {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$trimmed/v1/backup');
    if (uri == null || uri.host.isEmpty) return null;
    if (!uri.isScheme('https') && !uri.isScheme('http')) return null;
    return uri;
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer ${token.trim()}',
        'Content-Type': 'application/json; charset=utf-8',
      };

  Failure _httpFailure(int statusCode) => switch (statusCode) {
        401 || 403 => const NetworkFailure('Token de acesso recusado pelo servidor.'),
        413 => const NetworkFailure('O backup ficou grande demais para o servidor.'),
        _ => NetworkFailure('O servidor respondeu com erro $statusCode.'),
      };
}
