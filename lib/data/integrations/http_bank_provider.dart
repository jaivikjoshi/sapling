import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/enum_serialization.dart';
import '../../domain/integrations/transaction_importer.dart';

class HttpBankProvider implements BankProvider {
  const HttpBankProvider({
    required http.Client client,
    required Uri baseUri,
    this.providerIdValue = 'trusted_aggregator',
    this.displayNameValue = 'Trusted bank connection',
  }) : _client = client,
       _baseUri = baseUri;

  final http.Client _client;
  final Uri _baseUri;
  final String providerIdValue;
  final String displayNameValue;

  @override
  String get providerId => providerIdValue;

  @override
  String get displayName => displayNameValue;

  @override
  bool get usesTrustedAggregator => true;

  @override
  Future<BankConnectionStatus> connectionStatus() async {
    final response = await _client.get(_endpoint('/bank/status'));
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    final status = body['status']?.toString();
    return _statusFromString(status);
  }

  @override
  Future<BankConnectionIntent> startConnection() async {
    final response = await _client.post(
      _endpoint('/bank/connect'),
      headers: _jsonHeaders,
    );
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    return BankConnectionIntent(
      providerId: body['providerId']?.toString() ?? providerId,
      displayName: body['displayName']?.toString() ?? displayName,
      consentCopy:
          body['consentCopy']?.toString() ??
          'Leko will send you to a trusted aggregator to connect your bank. Leko never stores your bank username or password.',
      authorizationUrl: _optionalUri(body['authorizationUrl']),
    );
  }

  @override
  Future<List<ImportedTransactionDraft>> preview() async {
    final response = await _client.get(_endpoint('/bank/transactions/preview'));
    _throwIfUnsuccessful(response);
    final body = jsonDecode(response.body);
    final rawDrafts = body is Map<String, Object?> ? body['drafts'] : body;
    if (rawDrafts is! List) return const [];
    return rawDrafts
        .whereType<Map>()
        .map((draft) => ImportedTransactionDraftJson.fromJson(draft))
        .toList(growable: false);
  }

  @override
  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  ) async {
    final response = await _client.post(
      _endpoint('/bank/transactions/import'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'drafts': drafts
            .map(ImportedTransactionDraftJson.toJson)
            .toList(growable: false),
      }),
    );
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    return TransactionImportResult(
      createdCount: _asInt(body['createdCount']),
      skippedCount: _asInt(body['skippedCount']),
      message: body['message']?.toString(),
    );
  }

  Uri _endpoint(String path) => _baseUri.replace(
    path: '${_baseUri.path.replaceFirst(RegExp(r'/$'), '')}$path',
  );
}

class ImportedTransactionDraftJson {
  const ImportedTransactionDraftJson._();

  static ImportedTransactionDraft fromJson(Map<Object?, Object?> json) {
    final amount = _asDouble(json['amount']);
    final source =
        _tryEnum(json['source'], TransactionImportSource.values) ??
        TransactionImportSource.bankAggregator;
    return ImportedTransactionDraft(
      sourceId:
          json['sourceId']?.toString() ??
          json['id']?.toString() ??
          _stableSourceIdFallback(source: source, json: json),
      source: source,
      amount: amount,
      date: _asDate(json['date']) ?? DateTime.now(),
      type:
          _tryEnum(json['type'], ImportedTransactionType.values) ??
          ImportedTransactionType.expense,
      merchant: _optionalString(json['merchant']),
      categorySuggestion: _optionalString(json['categorySuggestion']),
      taxAmount: _optionalDouble(json['taxAmount']),
      note: _optionalString(json['note']),
      attachmentId: _optionalString(json['attachmentId']),
      reviewStatus:
          _tryEnum(json['reviewStatus'], ImportReviewStatus.values) ??
          ImportReviewStatus.pending,
      confidence: _optionalDouble(json['confidence']),
    );
  }

  /// When the provider omits ids, derive a stable key from immutable fields
  /// so re-previewing the same transaction cannot bypass import dedup.
  static String _stableSourceIdFallback({
    required TransactionImportSource source,
    required Map<Object?, Object?> json,
  }) {
    final amount = _asDouble(json['amount']);
    final date = _asDate(json['date'])?.toIso8601String().split('T').first ?? '';
    final merchant = _optionalString(json['merchant']) ?? '';
    final type = json['type']?.toString() ?? '';
    return '${source.name}:$date:$amount:$merchant:$type';
  }

  static Map<String, Object?> toJson(ImportedTransactionDraft draft) {
    return {
      'sourceId': draft.sourceId,
      'source': enumToDb(draft.source),
      'amount': draft.amount,
      'date': draft.date.toIso8601String(),
      'type': enumToDb(draft.type),
      'merchant': draft.merchant,
      'categorySuggestion': draft.categorySuggestion,
      'taxAmount': draft.taxAmount,
      'note': draft.note,
      'attachmentId': draft.attachmentId,
      'reviewStatus': enumToDb(draft.reviewStatus),
      'confidence': draft.confidence,
    };
  }
}

const _jsonHeaders = {'Content-Type': 'application/json'};

Map<String, Object?> _jsonMap(http.Response response) {
  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return const {};
}

void _throwIfUnsuccessful(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw HttpBankProviderException(
    'Bank provider request failed with ${response.statusCode}.',
  );
}

BankConnectionStatus _statusFromString(String? value) {
  return _tryEnum(value, BankConnectionStatus.values) ??
      BankConnectionStatus.unavailable;
}

T? _tryEnum<T extends Enum>(Object? value, List<T> values) {
  if (value == null) return null;
  final raw = value.toString();
  for (final candidate in values) {
    if (candidate.name == raw || enumToDb(candidate) == raw) {
      return candidate;
    }
  }
  return null;
}

Uri? _optionalUri(Object? value) {
  if (value == null) return null;
  return Uri.tryParse(value.toString());
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _asDouble(Object? value) => _optionalDouble(value) ?? 0;

double? _optionalDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString().replaceAll(',', ''));
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class HttpBankProviderException implements Exception {
  const HttpBankProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
