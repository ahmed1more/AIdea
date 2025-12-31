# aidea

aidea is app that simplifies watching videos by beautiful well written notes.

## Getting Started

# 📁 Project Structure

```
lib/
├── models/
│   ├── app_user.dart
│   └── video_note.dart
├── providers/
│   ├── auth_provider.dart
│   └── notes_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   ├── add_note_screen.dart
│   │   ├── home_screen.dart
│   │   └── note_detail_screen.dart
│   └── splash_screen.dart
├── services/
│   ├── auth_service.dart
│   └── database_service.dart
├── widgets/
│   └── note_card.dart
├── firebase_options.dart
└── main.dart

```

# Run the App

### For Android
```
flutter run
```

### For Web
```
flutter run -d chrome
```

# 🔐 Firebase Authentication Flow

Sign Up: User creates account with email/password
Sign In: User logs in with credentials
Auto-Login: Firebase maintains session
Password Reset: Email-based password recovery
Sign Out: User can log out from any device


# 🗄️ Firestore Data Structure

### users collection
```
json{
  "userId": {
    "email": "user@example.com",
    "name": "John Doe",
    "avatarUrl": "https://...",
    "createdAt": Timestamp
  }
}
```
### notes collection
```
json{
  "noteId": {
    "title": "Quantum Mechanics Basics",
    "content": "Notes about quantum mechanics...",
    "tags": ["physics", "quantum"],
    "category": "Physics",
    "isFavorite": false,
    "userId": "userId",
    "createdAt": Timestamp,
    "updatedAt": Timestamp
  }
}
```

# 🌟 Key Features Implemented

### ✅ Authentication

Email/password registration
Login with validation
Password reset
Auto sign-in
Sign out
Protected routes

### ✅ Note Management

Create notes (saved to Firestore)
Edit notes (real-time updates)
Delete notes
Toggle favorites
Real-time synchronization

### ✅ Search & Filter

Search by title, content, tags
Filter by category
Show favorites only
Real-time filtering

### ✅ UI/UX

Material Design 3
Dark mode support
Responsive layout
Loading states
Error handling
Pull to refresh

### ✅ Offline Support

Firestore caches data automatically
Works offline
Syncs when online
Conflict resolution



### 📚 Learning Resources

Firebase Documentation
FlutterFire Documentation
Flutter Documentation
Riverpod Documentation