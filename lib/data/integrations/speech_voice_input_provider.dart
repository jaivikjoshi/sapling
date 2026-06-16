import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/integrations/transaction_importer.dart';

class SpeechVoiceInputProvider implements VoiceInputProvider {
  SpeechVoiceInputProvider({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  @override
  Future<VoiceInputResult> listen() async {
    final ready = await _speech.initialize();
    if (!ready) {
      return const VoiceInputResult(
        transcript: '',
        confidence: 0,
        permissionDenied: true,
      );
    }

    final completer = Completer<VoiceInputResult>();
    SpeechRecognitionResult? latest;
    await _speech.listen(
      onResult: (result) {
        latest = result;
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(_toVoiceResult(result));
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        await _speech.stop();
        return _toVoiceResult(latest);
      },
    );
  }

  VoiceInputResult _toVoiceResult(SpeechRecognitionResult? result) {
    return VoiceInputResult(
      transcript: result?.recognizedWords.trim() ?? '',
      confidence: (result?.confidence ?? 0).clamp(0, 1).toDouble(),
    );
  }
}
