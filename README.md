# iSmart Shop - Intelligent Shop Assistant

An Android mobile application designed to help small shop owners in Uganda manage their business transactions efficiently using voice commands and intelligent text processing.

## Features

### 🎤 Voice-Based Transaction Recording
- Record transactions using voice input
- Automatic speech-to-text conversion
- Support for English and Luganda languages

### 📝 Text-Based Entry
- Manual transaction entry
- NLP-powered transaction parsing
- Automatic amount and category extraction

### 📊 Reports & Analytics
- Daily, weekly, and monthly summaries
- Sales vs expenses tracking
- Simple visual charts

### 📱 User-Friendly Interface
- Large buttons for easy interaction
- Minimal text for accessibility
- Offline-first capability (limited)

## Tech Stack

| Purpose | Technology |
|---------|------------|
| UI Framework | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore) |
| Speech Recognition | Google Speech-to-Text |
| NLP Processing | Custom Dart-based NLP |
| State Management | Provider |
| Charts | FlChart |

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/
│   ├── transaction.dart      # Transaction data model
│   └── user.dart             # User data model
├── providers/
│   ├── auth_provider.dart    # Authentication state
│   ├── transaction_provider.dart  # Transaction state
│   └── language_provider.dart    # Language settings
├── services/
│   ├── nlp_service.dart      # NLP processing
│   ├── speech_service.dart   # Speech-to-text
│   └── translation_service.dart # Luganda translation
├── screens/
│   ├── splash_screen.dart    # App splash
│   ├── onboarding_screen.dart # Welcome & language
│   ├── login_screen.dart     # User login
│   ├── register_screen.dart  # User registration
│   ├── home_screen.dart      # Dashboard
│   ├── voice_recording_screen.dart # Voice input
│   ├── text_entry_screen.dart # Manual entry
│   ├── transaction_review_screen.dart # Review & save
│   ├── transactions_list_screen.dart # Transaction history
│   ├── reports_screen.dart   # Analytics
│   └── settings_screen.dart  # App settings
└── utils/
    ├── colors.dart           # App colors & styles
    └── theme.dart            # App theme
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Firebase account
- Android Studio / VS Code

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/ismart-shop.git
cd ismart-shop
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android app with your package name
   - Download `google-services.json` and place in `android/app/`
   - Enable Firebase Authentication (Email/Password)
   - Enable Cloud Firestore

4. Update Firebase configuration:
   - Edit `lib/firebase_options.dart` with your Firebase config

5. Run the app:
```bash
flutter run
```

## Usage

### Recording a Transaction by Voice
1. Tap the microphone button on the home screen
2. Speak your transaction (e.g., "Sold bread for 5000 shillings")
3. Review the extracted information
4. Tap "Save" to record

### Adding a Transaction Manually
1. Tap "Add by Text" on the home screen
2. Enter your transaction details
3. Review and save

### Example Phrases
- "Sold bread for 5000 shillings"
- "Spent 20000 on transport"
- "Sold milk to customer for 3000"
- "Bought stock for 500000"

## Language Support
- English
- Luganda (Ugandan language)

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License.

## Acknowledgments
- Flutter Team for the amazing framework
- Firebase for backend services
- Small shop owners who inspired this project
