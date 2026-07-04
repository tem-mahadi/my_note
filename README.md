# My Notes App 📝

A beautiful, modern, and minimalist Notes Management Application built with Flutter and Cloud Firestore.

## Features ✨

- **Create Notes**: Add new notes with a title and a description.
- **Real-Time Sync**: Notes are updated instantly across all your devices using Cloud Firestore streams.
- **Update Notes**: Edit and modify your existing notes at any time.
- **Delete Notes**: Swipe-to-delete with confirmation dialogs.
- **Premium UI**: 
  - Dark mode with deep indigo/purple gradient palette.
  - Glassmorphism note cards.
  - Custom Inter typography (via Google Fonts).
  - Smooth page transitions and staggered list entry animations.

## Tech Stack 🛠️

- **Framework**: Flutter
- **Database**: Firebase Cloud Firestore
- **State Management & Async**: Flutter `StreamBuilder`

## Setup & Installation 🚀

1. **Clone the repository**
   ```bash
   git clone <repository_url>
   cd my_note
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Ensure you have a Firebase project created.
   - Add your Android app to the Firebase project and download `google-services.json` into `android/app/`.
   - Create a Firestore Database in your Firebase console.
   - For development, update your Firestore Security Rules to:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if true;
         }
       }
     }
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Screenshots 📸

*(Add your screenshots here)*

## Architecture 🏗️

The project follows a clean architecture separating UI, services, and models:
- `lib/models/`: Contains the `Note` data model.
- `lib/services/`: Contains `NoteService` for Firestore CRUD operations.
- `lib/screens/`: Contains the UI screens (`NotesListScreen`, `AddEditNoteScreen`).
