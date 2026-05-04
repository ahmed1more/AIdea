import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/app_theme.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<dynamic> recommendations = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      // جيب التوكن بتاع المستخدم من فايربيز
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      // ابعت ريكويست للسيرفر
      final response = await http.get(
        Uri.parse('https://atinc1-aidea-server.hf.space/recommendations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recommendations = data['recommendations'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'حصل خطأ في جلب البيانات';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حصل خطأ: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // لو لسه بيحمل
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // لو حصل خطأ
    if (error != null) {
      return Center(child: Text(error!));
    }

    // لو مفيش فيديوهات
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.lightbulb,
              size: 64,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommendations',
              style: AppTheme.headline3(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart suggestions based on your study habits will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // عرض الفيديوهات
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final video = recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              // افتح الفيديو على يوتيوب
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الفيديو
                Image.network(
                  video['thumbnail'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم الفيديو
                      Text(
                        video['title'],
                        style: AppTheme.headline3(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // اسم القناة
                      Text(
                        video['channelTitle'],
                        style: AppTheme.bodyMedium(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}