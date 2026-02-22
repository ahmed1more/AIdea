import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  /// Generate notes from a video URL/title using the configured AI model.
  /// Returns a map with 'notes' (String) and 'keyPoints' (List<String>).
  static Future<Map<String, dynamic>> generateNotes({
    required String videoUrl,
    required String videoTitle,
    required String model, // 'gemini', 'openai', or 'aidea'
    required String apiKey,
    String? aideaUrl,
    String? idToken,
    String language = 'en',
  }) async {
    if (model == 'aidea') {
      return await _callAideaModel(videoUrl, aideaUrl!, idToken!, language);
    }

    final prompt =
        '''
You are a note-taking assistant. Given a video URL and title, generate comprehensive, well-structured notes.

Video Title: $videoTitle
Video URL: $videoUrl

Generate notes in the following JSON format (respond ONLY with valid JSON, no markdown):
{
  "notes": "Detailed, well-structured notes about the video content. Include sections like Summary, Key Concepts, and Conclusion. Use proper formatting with line breaks.",
  "keyPoints": ["Key point 1", "Key point 2", "Key point 3", "Key point 4", "Key point 5"]
}

Make the notes insightful, educational, and well-organized. Include at least 3-5 key points.
''';

    if (model == 'gemini') {
      return await _callGemini(prompt, apiKey);
    } else {
      return await _callOpenAI(prompt, apiKey);
    }
  }

  static Future<Map<String, dynamic>> _callAideaModel(
    String videoUrl,
    String baseUrl,
    String idToken,
    String language,
  ) async {
    // Ensure URL ends with /generate
    final urlString = baseUrl.endsWith('/')
        ? '${baseUrl}generate'
        : '$baseUrl/generate';
    final url = Uri.parse(urlString);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'youtube_url': videoUrl, 'language': language}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AIdea Model error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final taskId = data['task_id'];

    // Poll for status
    return await _pollAideaTaskStatus(taskId, baseUrl, idToken);
  }

  static Future<Map<String, dynamic>> _pollAideaTaskStatus(
    String taskId,
    String baseUrl,
    String idToken,
  ) async {
    final statusUrlString = baseUrl.endsWith('/')
        ? '${baseUrl}status/$taskId'
        : '$baseUrl/status/$taskId';
    final url = Uri.parse(statusUrlString);

    while (true) {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode != 200) {
        throw Exception('Status check failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final status = data['status'];

      if (status == 'completed') {
        return {
          'notes': data['notes'] ?? 'Notes generation completed.',
          'keyPoints': List<String>.from(data['keyPoints'] ?? []),
        };
      } else if (status == 'failed') {
        throw Exception(
          'Generation failed: ${data['message'] ?? 'Unknown error'}',
        );
      }

      // Wait 3 seconds before next poll
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  static Future<Map<String, dynamic>> _callGemini(
    String prompt,
    String apiKey,
  ) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      String detailedError = errorBody;
      try {
        final errorData = jsonDecode(errorBody);
        detailedError = errorData['error']?['message'] ?? errorBody;
      } catch (_) {}

      if (response.statusCode == 429) {
        throw Exception(
          'Gemini API: Rate limit exceeded (429). Please try again later.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Gemini API: Access denied (403). Check your API key and permissions. Details: $detailedError',
        );
      } else if (errorBody.contains('SAFETY')) {
        throw Exception(
          'Gemini API: Content flagged by safety filters. Try a different video.',
        );
      }
      throw Exception(
        'Gemini API error (${response.statusCode}): $detailedError',
      );
    }

    final data = jsonDecode(response.body);
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

    return _parseAiResponse(text);
  }

  static Future<Map<String, dynamic>> _callOpenAI(
    String prompt,
    String apiKey,
  ) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      String detailedError = errorBody;
      try {
        final errorData = jsonDecode(errorBody);
        detailedError = errorData['error']?['message'] ?? errorBody;
      } catch (_) {}

      if (response.statusCode == 429) {
        throw Exception(
          'OpenAI API: Rate limit exceeded (429). Check your usage limits.',
        );
      } else if (response.statusCode == 401) {
        throw Exception(
          'OpenAI API: Invalid API key (401). Please check your settings.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'OpenAI API: Access denied (403). Your key might not have access to gpt-4o-mini.',
        );
      }
      throw Exception(
        'OpenAI API error (${response.statusCode}): $detailedError',
      );
    }

    final data = jsonDecode(response.body);
    final text = data['choices']?[0]?['message']?['content'] ?? '';

    return _parseAiResponse(text);
  }

  static Map<String, dynamic> _parseAiResponse(String text) {
    try {
      String cleaned = text.trim();

      // Better extraction using Regex to find JSON block if text around it exists
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.stringMatch(cleaned);

      if (match != null) {
        cleaned = match;
      }

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return {
        'notes': parsed['notes'] ?? 'No notes generated in the response.',
        'keyPoints': List<String>.from(parsed['keyPoints'] ?? []),
      };
    } catch (e) {
      // If JSON parsing fails, return raw text as notes but note the failure
      return {
        'notes':
            'Note: AI response was not in expected format, showing raw text:\n\n${text.trim()}',
        'keyPoints': <String>[],
      };
    }
  }
}
