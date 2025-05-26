import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class GeminiService {
  static const String apiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your API key
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String modelName = 'gemini-2.0-flash';

  final uuid = const Uuid();

  Future<String> generateBusinessContent(String prompt) async {
    try {
      final url = Uri.parse('$baseUrl/models/$modelName:generateContent?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      };

      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(requestBody));

      if (response.statusCode != 200) {
        debugPrint('Failed to generate content: ${response.statusCode}');
        return 'Error: Unable to generate content. Please try again.';
      }

      final responseData = jsonDecode(response.body);
      final responseText = responseData['candidates'][0]['content']['parts'][0]['text'];

      return responseText;
    } catch (e) {
      debugPrint('Error generating content: $e');
      return 'Error: $e';
    }
  }

  Future<List<String>> identifyIngredientsFromKitchenPhoto(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/models/$modelName:generateContent?key=$apiKey');

      // Read image file and encode to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = '''
Look at this image of kitchen ingredients and identify all food items visible.

Return only a list of individual ingredients, one per line. Be specific about the items.
Don't include any explanations, descriptions, or non-food items.
''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
      };

      // Send POST request
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(requestBody));

      // Check for successful response
      if (response.statusCode != 200) {
        debugPrint('Failed to identify ingredients: ${response.statusCode}');
        return [];
      }

      // Parse response data
      final responseData = jsonDecode(response.body);
      String responseText = '';
      try {
        responseText = responseData['candidates'][0]['content']['parts'][0]['text'];
      } catch (e) {
        debugPrint('Error extracting text from response: $e');
        return [];
      }

      // Split into lines
      List<String> lines = responseText.split('\n');

      // Filter and clean the lines
      List<String> ingredients = [];
      for (String line in lines) {
        String cleaned = line.trim();
        // Remove numbering or bullet points if present
        cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s*|-\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          ingredients.add(cleaned);
        }
      }

      debugPrint('Identified Ingredients: $ingredients');
      return ingredients;
    } catch (e) {
      debugPrint('Error identifying ingredients: $e');
      return [];
    }
  }

  Future<String> generateBusinessPlan(Map<String, dynamic> businessInfo) async {
    final prompt = '''
Create a detailed business plan for a ${businessInfo['industry']} business named "${businessInfo['name']}".

Business Description:
${businessInfo['description']}

Include the following sections:
1. Executive Summary
2. Company Description
3. Market Analysis
4. Organization & Management
5. Service/Product Line
6. Marketing & Sales Strategy
7. Financial Projections
8. Funding Request (if applicable)

Make the business plan professional, concise, and ready for presentation to potential investors or stakeholders.
''';

    return await generateBusinessContent(prompt);
  }

  Future<String> generateMarketingContent(String businessName, String industry, String contentType) async {
    final prompt = '''
Create professional marketing content for a $industry business named "$businessName".
Content type: $contentType

The content should be engaging, professional, and tailored to the $industry industry.
Include compelling calls to action and unique selling propositions.
''';

    return await generateBusinessContent(prompt);
  }

  Future<String> generateLegalDocument(String documentType, Map<String, dynamic> businessInfo) async {
    final prompt = '''
Generate a professional $documentType for a ${businessInfo['industry']} business named "${businessInfo['name']}".

Business Description:
${businessInfo['description']}

The document should be comprehensive, legally sound (while noting it's not legal advice), and follow standard industry practices for this type of document.
''';

    return await generateBusinessContent(prompt);
  }
}
