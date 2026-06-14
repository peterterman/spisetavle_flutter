import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAiService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static Future<List<Map<String, dynamic>>> analyzeMealPhoto(
    File imageFile,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4.1-mini',
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': '''
Analyser dette måltidsfoto.

Returner KUN gyldig JSON i dette format:

{
  "foods": [
    {"name": "fødevarenavn", "grams": 100}
  ]
}

Brug danske fødevarenavne.
Estimer gram forsigtigt.
''',
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/jpeg;base64,$base64Image',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenAI fejl: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['output'][0]['content'][0]['text'] as String;

    final cleanedText = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = cleanedText.indexOf('{');
    final end = cleanedText.lastIndexOf('}');

    if (start == -1 || end == -1) {
      throw Exception('Kunne ikke finde JSON i svaret: $text');
    }

    final jsonText = cleanedText.substring(start, end + 1);
    final jsonResult = jsonDecode(jsonText);

    final foods = jsonResult['foods'] as List<dynamic>;

    return foods
        .map(
          (item) => {'name': item['name'].toString(), 'grams': item['grams']},
        )
        .toList();
  }
}
