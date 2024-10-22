import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const _apiKey = '6050f53a38614305836a51af433ba4a3'; // Replace with your API key
  static const _endpoint = 'https://donatepath.cognitiveservices.azure.com/';

  Future<String> translate(String text, String targetLanguage) async {
    final url = Uri.parse('$_endpoint&to=$targetLanguage');
    
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode([
        {'Text': text}
      ]),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse[0]['translations'][0]['text'];
    } else {
      throw Exception('Failed to translate text: ${response.statusCode}');
    }
  }
}
