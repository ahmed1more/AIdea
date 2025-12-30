# AIdea

AIdea is app that simplifies watching videos by beautiful well written notes.

## Getting Started

This project is a starting point for a Flutter application.

# 📁 Project Structure

```
lib/
├── main.dart                       # App entry point with Firebase init
├── firebase_options.dart           # Generated Firebase config
├── models/                         # Data models
│   └── note_model.dart            # Note & UserProfile models
├── providers/                      # State management (Riverpod)
│   ├── auth_provider.dart         # Firebase Auth logic
│   └── notes_provider.dart        # Firestore CRUD operations
├── screens/                        # UI screens
│   ├── home_screen.dart           # Main notes list
│   ├── note_editor_screen.dart    # Create/edit notes
│   ├── note_detail_screen.dart    # View note details
│   ├── settings_screen.dart       # App settings
│   ├── splash_screen.dart         # Loading screen
│   └── auth/
│       ├── login_screen.dart      # Firebase sign in
│       └── register_screen.dart   # Firebase sign up
└── widgets/                        # Reusable widgets
    ├── note_card.dart             # Note display card
    ├── search_bar_widget.dart     # Search input
    └── tag_input_widget.dart      # Tag management
```

# Run the App

### For Android
flutter run

### For Web
flutter run -d chrome

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