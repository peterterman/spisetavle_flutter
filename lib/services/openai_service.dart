import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Simply/OpenAI-proxy for SpiseTavle.
/// Samme princip som Horar: appen kalder Simply, og Simply kalder OpenAI.
const String kSpiseTavleAiEndpoint = String.fromEnvironment(
  'SPISETAVLE_AI_ENDPOINT',
  defaultValue: 'https://www.toft-terman.dk/spisetavle/analyze-image.php',
);

const String kSpiseTavleAppToken = String.fromEnvironment(
  'SPISETAVLE_APP_TOKEN',
  defaultValue: '',
);

/// Sendes med i kaldet til Simply. Den ligger ikke i configfilen.
const String kSpiseTavleAgent = String.fromEnvironment(
  'SPISETAVLE_AGENT',
  defaultValue: 'spisetavle_flutter',
);

const String kSpiseTavleApiUserAgent = 'SpiseTavleFlutter/1.0 PeterTerman';

class OpenAiService {
  static const String apiUrl = kSpiseTavleAiEndpoint;
  static const Duration timeout = Duration(seconds: 60);

  static Future<List<Map<String, dynamic>>> analyzeMealPhoto(
    File imageFile,
  ) async {
    final trimmedEndpoint = apiUrl.trim();
    if (trimmedEndpoint.isEmpty) {
      throw Exception('AI-endpoint er ikke sat.');
    }

    final uri = Uri.tryParse(trimmedEndpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw Exception('Ugyldig AI-endpoint: $trimmedEndpoint');
    }

    final request = http.MultipartRequest('POST', uri);

    request.fields['device_id'] = 'spisetavle';
    request.fields['agent'] = kSpiseTavleAgent;

    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = kSpiseTavleApiUserAgent;
    request.headers['X-SpiseTavle-Agent'] = kSpiseTavleAgent;

    if (kSpiseTavleAppToken.isNotEmpty) {
      request.headers['X-SpiseTavle-App-Token'] = kSpiseTavleAppToken;
    }

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      final response = await request.send().timeout(timeout);
      final body = await response.stream.bytesToString().timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server fejl: ${response.statusCode} $body');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Serveren svarede ikke med JSON-objekt.');
      }

      final foods = decoded['foods'] as List<dynamic>? ?? [];

      return foods.whereType<Map>().map((item) {
        return {
          'name': item['name'].toString(),
          'grams': item['grams'],
        };
      }).toList();
    } on TimeoutException {
      throw Exception('Timeout: AI-serveren svarede ikke i tide.');
    } on SocketException catch (e) {
      throw Exception('Kan ikke kontakte AI-serveren: ${e.message}');
    }
  }
}
