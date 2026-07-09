import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAiService {
  static const String apiUrl = 'https://api.toft-terman.dk/analyze-image';

  static Future<List<Map<String, dynamic>>> analyzeMealPhoto(
    File imageFile,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.fields['device_id'] = 'spisetavle';

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Server fejl: ${response.statusCode} $body');
    }

    final data = jsonDecode(body);

    final foods = data['foods'] as List<dynamic>? ?? [];

    return foods.map((item) {
      return {'name': item['name'].toString(), 'grams': item['grams']};
    }).toList();
  }
}
