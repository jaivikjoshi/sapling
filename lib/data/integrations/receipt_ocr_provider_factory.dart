import 'package:flutter/foundation.dart';

import '../../domain/integrations/transaction_importer.dart';
import 'mlkit_receipt_ocr_provider_stub.dart'
    if (dart.library.io) 'mlkit_receipt_ocr_provider_io.dart';

ReceiptOcrProvider createReceiptOcrProvider() {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return createMlKitReceiptOcrProvider();
  }
  return const UnsupportedReceiptOcrProvider();
}
