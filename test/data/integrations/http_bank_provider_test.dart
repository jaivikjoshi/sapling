import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leko/data/integrations/http_bank_provider.dart';
import 'package:leko/domain/integrations/transaction_importer.dart';

void main() {
  test('authenticates bank API requests with the Supabase session', () async {
    final provider = HttpBankProvider(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer user-jwt');
        expect(request.url.path, '/bank/status');
        return http.Response('''
          {
            "status": "connected",
            "institutionName": "Example Bank",
            "lastSyncAt": "2026-07-17T12:00:00Z",
            "accounts": [
              {
                "id": "account-1",
                "name": "Chequing",
                "mask": "1234",
                "currency": "CAD",
                "isSelected": true
              }
            ]
          }
        ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.com'),
      accessTokenProvider: () async => 'user-jwt',
    );

    final details = await provider.connectionDetails();

    expect(details.status, BankConnectionStatus.connected);
    expect(details.institutionName, 'Example Bank');
    expect(details.accounts.single.mask, '1234');
    expect(details.lastSyncAt, DateTime.utc(2026, 7, 17, 12));
  });

  test(
    'starts a backend bank connection with consent copy and auth URL',
    () async {
      final provider = HttpBankProvider(
        client: MockClient((request) async {
          expect(request.url.path, '/bank/connect');
          return http.Response('''
          {
            "providerId": "plaid",
            "displayName": "Plaid",
            "authorizationUrl": "https://link.example/connect",
            "consentCopy": "Connect with a trusted aggregator."
          }
          ''', 200);
        }),
        baseUri: Uri.parse('https://api.example.com'),
      );

      final intent = await provider.startConnection();

      expect(intent.providerId, 'plaid');
      expect(intent.displayName, 'Plaid');
      expect(
        intent.authorizationUrl,
        Uri.parse('https://link.example/connect'),
      );
      expect(intent.consentCopy, contains('trusted aggregator'));
    },
  );

  test('maps backend preview transactions into review drafts', () async {
    final provider = HttpBankProvider(
      client: MockClient((request) async {
        expect(request.url.path, '/v1/bank/transactions/preview');
        return http.Response('''
          {
            "drafts": [
              {
                "sourceId": "bank_txn_1",
                "source": "bank_aggregator",
                "amount": "12.50",
                "date": "2026-06-16",
                "type": "expense",
                "merchant": "Lunch Spot",
                "categorySuggestion": "Food",
                "confidence": 0.91
              }
            ]
          }
          ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.com/v1/'),
    );

    final drafts = await provider.preview();

    expect(drafts, hasLength(1));
    expect(drafts.single.source, TransactionImportSource.bankAggregator);
    expect(drafts.single.amount, 12.50);
    expect(drafts.single.merchant, 'Lunch Spot');
    expect(drafts.single.categorySuggestion, 'Food');
    expect(drafts.single.reviewStatus, ImportReviewStatus.pending);
  });

  test(
    'serializes approved transactions back to backend import endpoint',
    () async {
      final provider = HttpBankProvider(
        client: MockClient((request) async {
          expect(request.url.path, '/bank/transactions/import');
          expect(request.body, contains('"source":"bank_aggregator"'));
          return http.Response(
            '{"createdCount":1,"skippedCount":0,"message":"Imported"}',
            200,
          );
        }),
        baseUri: Uri.parse('https://api.example.com'),
      );

      final result = await provider.importApproved([
        ImportedTransactionDraft(
          sourceId: 'bank_txn_1',
          source: TransactionImportSource.bankAggregator,
          amount: 12.50,
          date: DateTime(2026, 6, 16),
          merchant: 'Lunch Spot',
          reviewStatus: ImportReviewStatus.approved,
          ledgerTransactionId: 'ledger-1',
        ),
      ]);

      expect(result.createdCount, 1);
      expect(result.skippedCount, 0);
      expect(result.message, 'Imported');
    },
  );

  test('persists review decisions and account selection', () async {
    final requests = <http.Request>[];
    final provider = HttpBankProvider(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/bank/accounts/select') {
          return http.Response('{"status":"connected"}', 200);
        }
        if (request.url.path == '/bank/status') {
          return http.Response('{"status":"connected"}', 200);
        }
        return http.Response('{"updatedCount":1}', 200);
      }),
      baseUri: Uri.parse('https://api.example.com'),
    );

    await provider.recordReviewDecision(
      'transaction-1',
      ImportReviewStatus.approved,
    );
    await provider.updateSelectedAccounts({'account-1'});

    expect(requests.first.body, contains('"reviewStatus":"approved"'));
    expect(
      requests
          .where((request) => request.url.path == '/bank/accounts/select')
          .single
          .body,
      contains('account-1'),
    );
  });
}
