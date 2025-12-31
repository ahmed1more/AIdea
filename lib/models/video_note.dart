import 'package:cloud_firestore/cloud_firestore.dart';

class VideoNote {
  final String id;
  final String userId;
  final String videoUrl;
  final String videoTitle;
  final String thumbnail;
  final String notes;
  final List<String> keyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  VideoNote({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.videoTitle,
    required this.thumbnail,
    required this.notes,
    required this.keyPoints,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'thumbnail': thumbnail,
      'notes': notes,
      'keyPoints': keyPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
    };
  }

  // Create from Firestore document
  factory VideoNote.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VideoNote(
      id: doc.id,
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      videoTitle: data['videoTitle'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      notes: data['notes'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  // Copy with method for updates
  VideoNote copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? videoTitle,
    String? thumbnail,
    String? notes,
    List<String>? keyPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return VideoNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      thumbnail: thumbnail ?? this.thumbnail,
      notes: notes ?? this.notes,
      keyPoints: keyPoints ?? this.keyPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
