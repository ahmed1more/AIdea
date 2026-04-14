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
  }) async {
    return await _callAideaModel(videoUrl, aideaUrl!, idToken!, language);
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
}
