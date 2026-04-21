import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/restaurant.dart';

class MenuAiService {
  static const _apiKeyKey = 'anthropic_api_key';
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
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 2048,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Extract all menu items from this image. Return a JSON array with objects containing: id (unique string), name (dish name), category (main/side/drink), description (optional string). Format as valid JSON array only, no other text.'
                },
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List;
        
        for (final block in content) {
          if (block['type'] == 'text') {
            final text = block['text'] as String;
            return _parseMenuItems(text);
          }
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
        
        return items.map((item) => MenuItem(
          id: (item['id'] ?? item['name'].hashCode).toString(),
          name: item['name'] ?? 'Unknown',
          category: _normalizeCategory(item['category'] ?? 'Main'),
          description: item['description'],
        )).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _normalizeCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('drink') || lower.contains('beverage')) {
      return 'Drink';
    }
    if (lower.contains('side') || lower.contains('appetizer') || lower.contains('starter')) {
      return 'Side';
    }
    return 'Main';
  }

  Future<List<MenuItem>?> analyzeMenuText(String text) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 2048,
          'messages': [
            {
              'role': 'user',
              'content': '''Analyze this menu text and extract all items. Return a JSON array with objects containing:
- id: unique string (use a short hash of the name)
- name: the dish name  
- category: categorize as "Main", "Side", or "Drink"
- description: brief description if available

Menu text:
$text

Return ONLY a valid JSON array, no other text.'''
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List;
        
        for (final block in content) {
          if (block['type'] == 'text') {
            final text = block['text'] as String;
            return _parseMenuItems(text);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
