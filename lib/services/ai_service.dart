import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  /// Generate notes from a video URL/title using the configured AI model.
  /// Returns a map with 'notes' (String) and 'keyPoints' (`List<String>`).
  static Future<Map<String, dynamic>> generateNotes({
    required String videoUrl,
    required String videoTitle,
    String? aideaUrl,
    String? idToken,
    String language = 'en',
    ValueChanged<Map<String, dynamic>>? onStatus,
  }) async {
    return await _callAideaModel(
      videoUrl,
      aideaUrl!,
      idToken!,
      language,
      onStatus,
    );
  }

  static Future<Map<String, dynamic>> _callAideaModel(
    String videoUrl,
    String baseUrl,
    String idToken,
    String language,
    ValueChanged<Map<String, dynamic>>? onStatus,
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
    return await _pollAideaTaskStatus(taskId, baseUrl, idToken, onStatus);
  }

  static Future<Map<String, dynamic>> _pollAideaTaskStatus(
    String taskId,
    String baseUrl,
    String idToken,
    ValueChanged<Map<String, dynamic>>? onStatus,
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
      if (data is Map<String, dynamic>) {
        onStatus?.call(data);
      }

      if (status == 'complete' || status == 'completed') {
        return {
          'notes': data['notes'] ?? 'Notes generation completed.',
          'keyPoints': List<String>.from(data['keyPoints'] ?? []),
          'category': data['category'] ?? 'Technology & AI',
          'suggested_category': data['suggested_category'],
          'videoDuration': data['videoDuration'] ?? 0,
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

  static Future<Map<String, dynamic>> generateSpeech({
    required String text,
    required String title,
    required String aideaUrl,
    required String idToken,
    String rate = '-10%',
  }) async {
    final urlString = aideaUrl.endsWith('/')
        ? '${aideaUrl}tts/generate'
        : '$aideaUrl/tts/generate';
    final url = Uri.parse(urlString);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'text': text, 'title': title, 'rate': rate}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Text to speech error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final audioUrl = data['audioUrl'] as String? ?? '';
    final baseUri = Uri.parse(aideaUrl.endsWith('/') ? aideaUrl : '$aideaUrl/');

    return {
      ...data,
      'audioUrl': audioUrl.startsWith('http')
          ? audioUrl
          : baseUri.resolve(audioUrl).toString(),
    };
  }

  /// Fetches video metadata (title, thumbnail) using YouTube oEmbed API.
  static Future<Map<String, String>> fetchVideoMetadata(String url) async {
    try {
      if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
        return {};
      }

      final oEmbedUrl = Uri.parse(
        'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json',
      );

      final response = await http.get(oEmbedUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'title': data['title'] as String? ?? '',
          'thumbnail': data['thumbnail_url'] as String? ?? '',
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching video metadata: $e');
      return {};
    }
  }

  /// Chat with a specific note — document-grounded Q&A.
  /// Returns the AI-generated answer string.
  static Future<String> chatWithNote({
    required String noteContent,
    required String question,
    List<Map<String, String>>? history,
    required String aideaUrl,
    required String idToken,
  }) async {
    try {
      final urlString = aideaUrl.endsWith('/')
          ? '${aideaUrl}chat/note'
          : '$aideaUrl/chat/note';
      final url = Uri.parse(urlString);

      final body = <String, dynamic>{
        'note_content': noteContent,
        'question': question,
      };
      if (history != null && history.isNotEmpty) {
        body['history'] = history;
      }

      debugPrint('📡 Sending chat/note request to $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ HTTP Error (${response.statusCode}): ${response.body}');
        throw Exception(
          'Chat error (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      return data['answer'] as String? ?? 'No response received.';
    } catch (e) {
      debugPrint('❌ Exception in chatWithNote: $e');
      rethrow;
    }
  }
}
