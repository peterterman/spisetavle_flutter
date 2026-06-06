import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeService {
  static Future<Map<String, dynamic>?> getFood(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode.json';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 1) {
      return null;
    }

    final product = json['product'];

    return {
      'name': product['product_name'] ?? '',
      'kcal': product['nutriments']['energy-kcal_100g'],
      'carbs': product['nutriments']['carbohydrates_100g'],
      'fat': product['nutriments']['fat_100g'],
      'protein': product['nutriments']['proteins_100g'],
    };
  }
}
