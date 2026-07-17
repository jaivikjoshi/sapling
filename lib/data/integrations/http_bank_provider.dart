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
    this.fallbackConsentCopy =
        'Leko will send you to a trusted aggregator to connect your bank. Leko never stores your bank username or password.',
    this.accessTokenProvider,
  }) : _client = client,
       _baseUri = baseUri;

  final http.Client _client;
  final Uri _baseUri;
  final String providerIdValue;
  final String displayNameValue;
  final String fallbackConsentCopy;
  final Future<String?> Function()? accessTokenProvider;

  @override
  String get providerId => providerIdValue;

  @override
  String get displayName => displayNameValue;

  @override
  bool get usesTrustedAggregator => true;

  @override
  Future<BankConnectionStatus> connectionStatus() async {
    final response = await _get('/bank/status');
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    final status = body['status']?.toString();
    return _statusFromString(status);
  }

  @override
  Future<BankConnectionDetails> connectionDetails() async {
    final response = await _get('/bank/status');
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    final rawAccounts = body['accounts'];
    return BankConnectionDetails(
      status: _statusFromString(body['status']?.toString()),
      providerId: _optionalString(body['providerId']),
      displayName: _optionalString(body['displayName']),
      institutionName: _optionalString(body['institutionName']),
      lastSyncAt: _asDate(body['lastSyncAt']),
      errorCode: _optionalString(body['errorCode']),
      accounts:
          rawAccounts is List
              ? rawAccounts
                  .whereType<Map>()
                  .map(
                    (account) => BankAccountDetails(
                      id: account['id']?.toString() ?? '',
                      name: account['name']?.toString() ?? 'Bank account',
                      mask: _optionalString(account['mask']),
                      type: _optionalString(account['type']),
                      subtype: _optionalString(account['subtype']),
                      currency: _optionalString(account['currency']),
                      currentBalance: _optionalDouble(
                        account['currentBalance'],
                      ),
                      availableBalance: _optionalDouble(
                        account['availableBalance'],
                      ),
                      isSelected: account['isSelected'] != false,
                    ),
                  )
                  .where((account) => account.id.isNotEmpty)
                  .toList(growable: false)
              : const [],
    );
  }

  @override
  Future<BankConnectionIntent> startConnection() async {
    final response = await _post('/bank/connect');
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    return BankConnectionIntent(
      providerId: body['providerId']?.toString() ?? providerId,
      displayName: body['displayName']?.toString() ?? displayName,
      consentCopy: body['consentCopy']?.toString() ?? fallbackConsentCopy,
      authorizationUrl: _optionalUri(body['authorizationUrl']),
    );
  }

  @override
  Future<List<ImportedTransactionDraft>> preview() async {
    final response = await _get('/bank/transactions/preview');
    if (response.statusCode == 202) {
      final body = _jsonMap(response);
      throw BankSyncPendingException(
        body['message']?.toString() ??
            'Your bank is still preparing transaction data.',
        retryAfterSeconds: _asInt(body['retryAfterSeconds']),
      );
    }
    _throwIfUnsuccessful(response);
    return _draftsFromResponse(response);
  }

  @override
  Future<List<ImportedTransactionDraft>> savedDrafts() async {
    final response = await _get('/bank/transactions/drafts');
    _throwIfUnsuccessful(response);
    return _draftsFromResponse(response);
  }

  @override
  Future<void> recordReviewDecision(
    String sourceId,
    ImportReviewStatus status,
  ) async {
    if (status != ImportReviewStatus.approved &&
        status != ImportReviewStatus.rejected) {
      throw ArgumentError.value(
        status,
        'status',
        'Must be approved or rejected',
      );
    }
    final response = await _post(
      '/bank/transactions/review',
      body: {
        'decisions': [
          {'sourceId': sourceId, 'reviewStatus': enumToDb(status)},
        ],
      },
    );
    _throwIfUnsuccessful(response);
    if (_asInt(_jsonMap(response)['updatedCount']) < 1) {
      throw const HttpBankProviderException(
        'That bank draft is no longer available. Sync again to refresh it.',
        statusCode: 409,
      );
    }
  }

  @override
  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  ) async {
    final response = await _post(
      '/bank/transactions/import',
      body: {
        'drafts': drafts
            .map(ImportedTransactionDraftJson.toJson)
            .toList(growable: false),
      },
    );
    _throwIfUnsuccessful(response);
    final body = _jsonMap(response);
    return TransactionImportResult(
      createdCount: _asInt(body['createdCount']),
      skippedCount: _asInt(body['skippedCount']),
      message: body['message']?.toString(),
    );
  }

  @override
  Future<BankConnectionDetails> updateSelectedAccounts(
    Set<String> accountIds,
  ) async {
    final response = await _post(
      '/bank/accounts/select',
      body: {'selectedAccountIds': accountIds.toList(growable: false)},
    );
    _throwIfUnsuccessful(response);
    return connectionDetails();
  }

  @override
  Future<void> disconnect() async {
    final response = await _request('DELETE', '/bank/connection');
    _throwIfUnsuccessful(response);
  }

  List<ImportedTransactionDraft> _draftsFromResponse(http.Response response) {
    final body = jsonDecode(response.body);
    final rawDrafts = body is Map<String, Object?> ? body['drafts'] : body;
    if (rawDrafts is! List) return const [];
    return rawDrafts
        .whereType<Map>()
        .map(ImportedTransactionDraftJson.fromJson)
        .toList(growable: false);
  }

  Future<http.Response> _get(String path) => _request('GET', path);

  Future<http.Response> _post(String path, {Map<String, Object?>? body}) =>
      _request('POST', path, body: body);

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = await accessTokenProvider?.call();
    final request = http.Request(method, _endpoint(path));
    request.headers.addAll({
      ..._jsonHeaders,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    if (body != null) request.body = jsonEncode(body);
    return http.Response.fromStream(await _client.send(request));
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
          '${source.name}:${json.hashCode}',
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
      accountId: _optionalString(json['accountId']),
      accountName: _optionalString(json['accountName']),
      pending: json['pending'] == true,
      ledgerTransactionId: _optionalString(json['ledgerTransactionId']),
    );
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
      'accountId': draft.accountId,
      'accountName': draft.accountName,
      'pending': draft.pending,
      'ledgerTransactionId': draft.ledgerTransactionId,
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
  String? providerMessage;
  try {
    providerMessage = _optionalString(_jsonMap(response)['message']);
  } catch (_) {
    // Fall back to the status-only message below.
  }
  throw HttpBankProviderException(
    providerMessage ??
        'Bank provider request failed with ${response.statusCode}.',
    statusCode: response.statusCode,
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
  const HttpBankProviderException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BankSyncPendingException implements Exception {
  const BankSyncPendingException(this.message, {this.retryAfterSeconds = 10});

  final String message;
  final int retryAfterSeconds;

  @override
  String toString() => message;
}
