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

  Future<List<MenuItem>> parseMenuImage(File imageFile) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No Gemini API key configured');
    }

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Extract all menu items from this menu image. Return ONLY a valid JSON array (not an object, just the raw array) where each element has: "id" (unique string), "name" (dish name, required), "description" (string or null), "itemNumber" (integer or null). Example: [{"id":"1","name":"Pizza Margherita","description":"Classic tomato and mozzarella","itemNumber":1}]'
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 4096,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = body['error']?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Gemini API error: $message');
    }

    final data = jsonDecode(response.body);
    final rawText =
        data['candidates']?[0]['content']?['parts']?[0]?['text'] as String?;

    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return _parseMenuItems(rawText);
  }

  List<MenuItem> _parseMenuItems(String text) {
    // Try direct decode first (works when responseMimeType returns clean JSON)
    dynamic decoded;
    try {
      decoded = jsonDecode(text.trim());
    } catch (_) {
      // Fall back to extracting the first [...] block from the text
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']') + 1;
      if (start < 0 || end <= start) {
        throw Exception('No JSON array found in response');
      }
      decoded = jsonDecode(text.substring(start, end));
    }

    // Handle both bare array and wrapped object (e.g. {"items":[...]})
    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final listValue = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => throw Exception('No array found in response object'),
      );
      items = listValue as List;
    } else {
      throw Exception('Unexpected response format');
    }

    if (items.isEmpty) {
      throw Exception('No menu items found in image');
    }

    return items.asMap().entries.map((entry) {
      final v = entry.value as Map<String, dynamic>;
      return MenuItem(
        id: v['id']?.toString() ??
            '${v['name']}_${entry.key}'.hashCode.toString(),
        name: (v['name'] as String?)?.trim() ?? 'Unknown',
        description: (v['description'] as String?)?.trim().isEmpty ?? true
            ? null
            : (v['description'] as String).trim(),
        itemNumber: v['itemNumber'] as int? ?? entry.key + 1,
      );
    }).toList();
  }

  Future<List<MenuItem>> analyzeMenuText(String menuText) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No Gemini API key configured');
    }

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Analyze this menu text and extract all items. Return ONLY a valid JSON array where each element has: "id" (unique string), "name" (dish name, required), "description" (string or null), "itemNumber" (integer or null). Menu text: $menuText'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 4096,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = body['error']?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Gemini API error: $message');
    }

    final data = jsonDecode(response.body);
    final rawText =
        data['candidates']?[0]['content']?['parts']?[0]?['text'] as String?;

    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return _parseMenuItems(rawText);
  }
}