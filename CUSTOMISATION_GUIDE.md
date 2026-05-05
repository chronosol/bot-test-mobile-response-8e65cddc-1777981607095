# Business Chatbot — Customisation Guide

This template is designed so a business needs to touch **exactly one file** to create
their own branded chatbot app.

---

## Step 1 — Edit `lib/core/constants/app_config.dart`

```dart
static const String businessName   = 'Your Business Name';
static const String tagline        = 'Your slogan';
static const String botName        = 'Your Bot Name';  // e.g. "Aria", "Max", "Zara"
static const String botRole        = 'Customer Support';
static const String welcomeMessage = "Hi! I'm [Bot], how can I help?";

static const String primaryColorHex = '#6C63FF';  // Your brand colour
static const String accentColorHex  = '#FF6584';  // Accent / CTA colour

static const String apiBaseUrl      = 'https://api.yourdomain.com';
static const String organisationId  = 'org_abc123';  // From your backend

static const List<String> quickReplies = [
  '💰 Pricing',
  '📦 My Orders',
  '📞 Support',
];
```

That's it. Run `flutter build apk --release` and you have a branded APK.

---

## Step 2 — Add your logo / avatar

Replace these files:
- `assets/images/logo.png`        — Your company logo (512×512 transparent PNG)
- `assets/images/bot_avatar.png`  — Bot avatar image (512×512 PNG, optional)

---

## Step 3 — Connect your AI backend

Your backend must expose one endpoint:

```
POST /v1/chat
Headers:
  Content-Type: application/json
  X-Org-ID: {organisationId}

Body:
{
  "session_id":      "uuid",
  "organisation_id": "org_abc123",
  "message":         "What are your prices?",
  "history": [
    { "role": "user",      "content": "Hello" },
    { "role": "assistant", "content": "Hi there!" }
  ]
}

Response:
{
  "reply": "Our pricing starts at ₦5,000/month..."
}
```

---

## Feature Flags

Toggle these in `AppConfig` to enable/disable features:

| Flag | Default | Description |
|---|---|---|
| `enableFileAttachments` | `true`  | Show attach button in input bar |
| `enableVoiceMessages`   | `false` | Show mic button when input is empty |
| `enableRatings`         | `true`  | Show rating option in menu |
| `enableTypingIndicator` | `true`  | Show animated dots while bot replies |
| `enableReadReceipts`    | `true`  | Show double-tick read status on messages |

---

## Architecture

```
lib/
├── main.dart                        ← Entry point
├── app.dart                         ← MaterialApp.router
├── core/
│   ├── constants/app_config.dart    ← THE file to edit ← ← ←
│   ├── theme/app_theme.dart         ← Auto-adapts to brand colours
│   └── routing/app_router.dart      ← Splash → Chat
└── features/
    ├── onboarding/screens/splash_screen.dart
    └── chat/
        ├── domain/message.dart          ← Data models
        ├── data/chat_repository.dart    ← API calls
        └── presentation/
            ├── controllers/chat_controller.dart   ← State (Riverpod)
            ├── screens/chat_screen.dart           ← Main UI
            └── widgets/
                ├── message_bubble.dart  ← User + bot bubbles
                ├── chat_input_bar.dart  ← Text input + send button
                └── quick_replies.dart   ← Suggestion chips
```

---

## Building for production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires Mac + Xcode)
flutter build ipa --release
```
