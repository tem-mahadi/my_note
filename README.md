# My Notes App 📝

A beautiful, modern, and minimalist Notes Management Application built with Flutter and Cloud Firestore — now with **on-device AI features** powered by OpenRouter.

## Features ✨

### Core notes
- **Create Notes**: Add new notes with a title and a description.
- **Real-Time Sync**: Notes are updated instantly across all your devices using Cloud Firestore streams.
- **Update Notes**: Edit and modify your existing notes at any time.
- **Delete Notes**: Swipe-to-delete with confirmation dialogs.

### AI features (OpenRouter)
- **Chat with note** — open a streaming chat constrained to the current note's content. Session history is kept in memory for the duration of the screen.
- **Task extractor** — parses a note into a JSON list of actionable tasks with priorities (`low` / `medium` / `high`) and renders them as a checkable list.
- **Brainstorm** — produces grouped ideas for the note, rendered as Markdown.
- **Continue writing** — inserts AI-generated text at the cursor while you are typing, preserving the note's tone.
- **Semantic search** — type a query on the notes list and the app embeds the query + every note with OpenRouter embeddings, then ranks by cosine similarity. Results are returned with a `% match` badge.

### Premium UI
- Dark mode with deep indigo/purple gradient palette.
- Glassmorphism note cards.
- Custom Inter typography (via Google Fonts).
- Smooth page transitions and staggered list entry animations.

## Tech Stack 🛠️

- **Framework**: Flutter (mobile + web)
- **Database**: Firebase Cloud Firestore
- **AI**: [OpenRouter](https://openrouter.ai) chat + embedding models
- **State management**: `provider`
- **Secure storage**: `flutter_secure_storage` (Keychain / EncryptedSharedPreferences)
- **Markdown rendering**: `flutter_markdown`
- **HTTP**: `package:http` with SSE streaming

## Setup & Installation 🚀

1. **Clone the repository**
   ```bash
   git clone https://github.com/tem-mahadi/my_note.git
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

4. **OpenRouter Configuration**
   - Create an account at [openrouter.ai](https://openrouter.ai) and grab an API key from the *Keys* page.
   - Run the app, open the **Profile** screen (top-right of the notes list), then tap **AI Settings**.
   - Paste the key, optionally adjust the chat / embedding model, and tap **Save**. The key is stored in the device's secure storage (Keychain on iOS, EncryptedSharedPreferences on Android) — it is **never** sent to the app author's servers.
   - Default chat model: `openai/gpt-4o-mini`
   - Default embedding model: `openai/text-embedding-3-small`
   - You can swap to any model that OpenRouter exposes (e.g. `anthropic/claude-3.5-sonnet`, `meta-llama/llama-3.1-70b-instruct`).

5. **(Optional) Proxy base URL**
   - For production, put your OpenRouter key on a server you control and have the app call that server instead. Set the **Proxy base URL** field in AI Settings to `https://your-proxy.example.com/v1`. Leave blank to talk to OpenRouter directly.

6. **Run the app**
   ```bash
   flutter run
   ```

## Security notes 🔐

- The OpenRouter key never leaves the device's secure storage. It is loaded into an in-memory cache on app start and used to sign requests.
- All AI prompts are centralised in `lib/core/ai/ai_prompts.dart` so you can audit and tweak them in one place.
- Notes are embedded after every save and the embedding is stored alongside the note in Firestore. The embedding is a vector of floating-point numbers — it does **not** contain your note's text.
- The "Continue Writing" feature only sends the text *before* your cursor to the model. The model never sees future text you haven't written yet.

## Multi-tenant notes ☁️

Every user's notes live in their own Firestore subcollection:

```
/users/{userMobile}/notes/{noteId}
```

The user id is the bdapps subscriber's mobile number, sourced from
`UserData.userNumber`. Each login therefore owns a fully isolated notes
namespace — users can never read or write each other's data, and `flutter
run` on a different device produces a new blank space.

`NoteService` gracefully no-ops when there is no active session
(`createNote` / `updateNote` become no-ops, `streamNotes()` emits an empty
list) so the UI stays functional during transitions like logout.

For development the Firestore rules in step 3 above are wide-open. For
production use rules that lock each user to their own subcollection, e.g.:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
        && request.auth.token.mobile == userId;
    }
  }
}
```

Add Firebase Auth (or sign the user in with the bdapps subscriber id) for
this to work end-to-end.

## Architecture 🏗️

The project follows a clean architecture separating UI, services, and models:

```
lib/
├── core/ai/                     # Reusable AI layer (provider-agnostic)
│   ├── ai_config.dart           # Centralised configuration + defaults
│   ├── ai_secure_storage.dart   # flutter_secure_storage wrapper w/ in-memory cache
│   ├── ai_exceptions.dart       # Sealed-style exception hierarchy
│   ├── ai_models.dart           # ChatMessage, ExtractedTask, BrainstormIdea, ...
│   ├── ai_prompts.dart          # All system + user prompt templates
│   ├── ai_service.dart          # OpenRouter HTTP client (chat / stream / embed)
│   └── semantic_search.dart     # Cosine similarity + ranking helpers
├── models/
│   └── note.dart                # Note model (with optional embedding field)
├── services/
│   └── note_service.dart        # Firestore CRUD + updateEmbedding / fetchAllNotes
├── screens/
│   ├── notes_list_screen.dart   # Stream of notes + semantic search bar
│   ├── add_edit_note_screen.dart# Editor with Continue Writing + AI menu
│   ├── ai_menu_sheet.dart       # Bottom sheet hub for the 3 note-scoped features
│   ├── ai_chat_screen.dart      # Streaming chat constrained to a note
│   ├── ai_tasks_screen.dart     # Checklist of extracted tasks
│   └── ai_brainstorm_screen.dart# Markdown-rendered grouped ideas
├── views/
│   ├── ai_settings_page.dart    # Configure API key, proxy URL, models
│   └── profile_page.dart        # Profile + AI Settings entry + logout / unsubscribe
├── theme/, widgets/             # Existing visual primitives
└── main.dart                    # MultiProvider with AIService + AISecureStorage
```

## Screenshots 📸

<p align="center">
  <img src="1.ScreenShots/Screenshot_20260704_182742.png" width="300" />
  <img src="1.ScreenShots/Screenshot_20260704_182813.png" width="300" />
</p>
