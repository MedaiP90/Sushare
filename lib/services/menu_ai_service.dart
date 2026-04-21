import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/restaurant.dart';

class MenuAiService {
  static const _apiKeyKey = 'gemini_api_key';
  final _secureStorage = const FlutterSecureStorage();
  
  Future<bool> hasApiKey() async {
    final key = await _secureStorage.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return _secureStorage.read(key: _apiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  Future<List<MenuItem>?> parseMenuImage(File imageFile) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Extract all menu items from this menu image. Return ONLY a valid JSON array with objects containing: id (unique string), name (dish name), description (string, optional), itemNumber (integer for ordering, optional). No other text. Example: [{"id":"1","name":"Pizza","description":"Delicious pizza","itemNumber":1}]'
                },
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          return _parseMenuItems(text);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  List<MenuItem>? _parseMenuItems(String text) {
    try {
      int start = text.indexOf('[');
      int end = text.lastIndexOf(']') + 1;
      
      if (start >= 0 && end > start) {
        final jsonStr = text.substring(start, end);
        final List<dynamic> items = jsonDecode(jsonStr);
        
        return items.asMap().entries.map((entry) => MenuItem(
          id: entry.value['id']?.toString() ?? entry.value['name'].hashCode.toString(),
          name: entry.value['name'] ?? 'Unknown',
          description: entry.value['description'],
          itemNumber: entry.value['itemNumber'] ?? entry.key + 1,
        )).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<MenuItem>?> analyzeMenuText(String text) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analyze this menu text and extract all items. Return ONLY a valid JSON array with objects containing: id (unique string), name (dish name), description (string, optional), itemNumber (integer for ordering, optional). Menu text: $text. No other text.'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          return _parseMenuItems(text);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}