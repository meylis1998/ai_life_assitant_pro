# AI Life Assistant Pro

A comprehensive AI-powered personal assistant Flutter application that combines multiple AI providers (Gemini, Claude, OpenAI) with real-world data APIs to create an intelligent life management system.

## 🚀 Features

### Core Features
- **Multi-Provider AI Intelligence**: Seamlessly switch between Gemini, Claude, and OpenAI
- **Real-time Streaming Responses**: Watch AI responses appear in real-time
- **Clean Architecture**: Enterprise-grade architecture with BLoC pattern
- **Offline Support**: Local caching for conversations
- **Dark Mode Support**: Beautiful UI with light and dark themes

### Planned Features
- Voice-powered interaction with speech-to-text
- Document RAG system for knowledge base
- Real-world API integrations (weather, news, finance)
- Smart automation and proactive suggestions
- Multi-language support

## 🏗️ Architecture

This project follows **Clean Architecture** principles with **BLoC** state management:

```
lib/
├── core/                 # Core functionality
│   ├── constants/       # App constants and themes
│   ├── errors/          # Error handling
│   ├── network/         # Network utilities
│   └── utils/           # Utility functions
│
├── features/            # Feature modules
│   └── ai_chat/        # AI Chat feature
│       ├── data/       # Data layer
│       ├── domain/     # Business logic
│       └── presentation/ # UI layer
│
└── injection_container.dart # Dependency injection
```

## 🛠️ Tech Stack

- **Flutter** 3.35.4
- **Dart** 3.9.2
- **State Management**: flutter_bloc (BLoC pattern)
- **Dependency Injection**: GetIt
- **AI SDKs**: Google Generative AI
- **Local Storage**: SharedPreferences, Hive
- **Architecture**: Clean Architecture with feature-based structure

## 📱 Getting Started

### Prerequisites

- Flutter SDK 3.35.4 or higher
- Dart SDK 3.9.2 or higher
- Android Studio / VS Code with Flutter extensions
- At least one AI API key (Gemini recommended for free tier)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ai_life_assistant_pro.git
cd ai_life_assistant_pro
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up environment variables**
```bash
# Copy the example env file
cp .env.example .env

# Edit .env and add your API keys
# At minimum, add your GEMINI_API_KEY
```

4. **Get API Keys**
- **Gemini API**: [Get free key](https://makersuite.google.com/app/apikey) (60 requests/min)
- **Claude API**: [Get key](https://console.anthropic.com/)
- **OpenAI API**: [Get key](https://platform.openai.com/api-keys)

5. **Run the app**
```bash
flutter run
```

## 🔑 API Configuration

The app supports multiple AI providers. Configure them in your `.env` file:

```env
GEMINI_API_KEY=your_key_here       # Required for Gemini
CLAUDE_API_KEY=your_key_here       # Optional
OPENAI_API_KEY=your_key_here       # Optional
```

## 🎯 Usage

1. **Start a conversation**: Type your message and press send
2. **Switch AI providers**: Use the provider selector at the top
3. **New conversation**: Tap the + icon in the app bar
4. **Clear chat**: Tap the clear icon to reset the conversation
5. **Long press messages**: Copy or delete individual messages

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📊 Performance

- **Response Time**: < 200ms for UI interactions
- **Streaming**: Real-time token-by-token display
- **Memory**: Efficient caching with automatic cleanup
- **Error Handling**: Comprehensive error recovery with retry logic

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google Generative AI team for the Gemini API
- Flutter team for the amazing framework
- BLoC library maintainers
- Open source community

## 📞 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/ai_life_assistant_pro](https://github.com/yourusername/ai_life_assistant_pro)

---

Built with ❤️ using Flutter and Clean Architecture