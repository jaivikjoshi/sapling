import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/integrations/receipt_text_parser.dart';
import '../../domain/integrations/transaction_importer.dart';

class MlKitReceiptOcrProvider implements ReceiptOcrProvider {
  const MlKitReceiptOcrProvider({
    ReceiptTextParser parser = const ReceiptTextParser(),
  }) : _parser = parser;

  final ReceiptTextParser _parser;

  @override
  Future<ReceiptExtractionResult> extract(ReceiptAttachment attachment) async {
    if (!attachment.mimeType.toLowerCase().startsWith('image/')) {
      return ReceiptExtractionResult(
        attachmentId: attachment.id,
        confidence: 0.2,
      );
    }

    final tempDir = await getTemporaryDirectory();
    final extension =
        p.extension(attachment.fileName).isEmpty
            ? _extensionForMimeType(attachment.mimeType)
            : p.extension(attachment.fileName);
    final file = File(p.join(tempDir.path, '${attachment.id}$extension'));
    await file.writeAsBytes(attachment.bytes, flush: true);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return _parser.parse(
        attachmentId: attachment.id,
        text: recognized.text,
        fallbackDate: DateTime.now(),
      );
    } finally {
      await recognizer.close();
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String _extensionForMimeType(String mimeType) {
    return switch (mimeType.toLowerCase()) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
  }
}

ReceiptOcrProvider createMlKitReceiptOcrProvider() {
  return const MlKitReceiptOcrProvider();
}
