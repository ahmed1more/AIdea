import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final bool isFavorite;
  final String userId;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.isFavorite = false,
    required this.userId,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? isFavorite,
    String? userId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category,
      'isFavorite': isFavorite,
      'userId': userId,
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      category: data['category'] as String?,
      isFavorite: data['isFavorite'] as bool? ?? false,
      userId: data['userId'] as String? ?? '',
    );
  }

  factory Note.fromMap(Map<String, dynamic> data, String id) {
    return Note(
      id: id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      category: data['category'] as String?,
      isFavorite: data['isFavorite'] as bool? ?? false,
      userId: data['userId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    tags,
    createdAt,
    updatedAt,
    category,
    isFavorite,
    userId,
  ];
}

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] as String,
      name: data['name'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt];
}
