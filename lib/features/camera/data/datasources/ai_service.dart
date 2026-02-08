import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/constants/api_keys.dart';

class AiService {
  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiKeys.geminiApiKey,
    );
  }

  Future<String> generateJournalFromImage(File image) async {
    try {
      final imageBytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            'Analyze this image and write a short, sentimental journal entry (1-2 sentences) in Korean as if it were my diary.',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text ?? 'AI failed to generate a caption.';
    } catch (e) {
      throw Exception('Failed to generate journal: $e');
    }
  }
}
