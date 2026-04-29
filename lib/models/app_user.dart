import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int notesCount;
  final String? gender;
  final String? birthDate;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.notesCount = 0,
    this.gender,
    this.birthDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'notesCount': notesCount,
      'gender': gender,
      'birthDate': birthDate,
    };
  }

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notesCount: data['notesCount'] ?? 0,
      gender: data['gender'],
      birthDate: data['birthDate'],
    );
  }

  // Copy with method for updates
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? notesCount,
    String? gender,
    String? birthDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      notesCount: notesCount ?? this.notesCount,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  // Convert to Map for local storage
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'notesCount': notesCount,
      'gender': gender,
      'birthDate': birthDate,
    };
  }

  // Create from local storage Map
  factory AppUser.fromJsonMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      notesCount: map['notesCount'] ?? 0,
      gender: map['gender'],
      birthDate: map['birthDate'],
    );
  }

  String toJson() => json.encode(toJsonMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromJsonMap(json.decode(source));
}
