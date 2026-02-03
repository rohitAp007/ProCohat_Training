# 💬 ProCohat - Real-Time Chat Application

**A production-ready, enterprise-level chat application built with Flutter, Supabase, and BLoC architecture.**

[![Flutter](https://img.shields.io/badge/Flutter-3.32.2-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.6.0-blue.svg)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![BLoC](https://img.shields.io/badge/State%20Management-BLoC-orange.svg)](https://bloclibrary.dev/)

---

## 🚀 Features

### 🔐 **Multi-Provider Authentication**
- ✅ **Email/Password** - Traditional authentication
- ✅ **Phone Number + OTP** - SMS verification
- ✅ **Google Sign-In** - One-click OAuth
- ✅ Unified login screen with beautiful UI
- ✅ Secure token-based sessions

### 💬 **Real-Time Messaging**
- ✅ **Instant messaging** with Supabase Realtime
- ✅ **Media support**: Images, videos, voice messages
- ✅ **Message status**: Sent, delivered, read
- ✅ **Typing indicators** (backend ready)
- ✅ **Read receipts** (backend ready)
- ✅ **Online/offline status** tracking

### 📡 **Broadcasting Services**
- ✅ **Presence tracking** - User online status
- ✅ **Typing indicators** - Real-time typing status
- ✅ **Read receipts** - Message read confirmation
- ✅ **Live updates** - WebSocket subscriptions

### 🎨 **Beautiful UI**
- ✅ WhatsApp-inspired design
- ✅ Material Design components
- ✅ Smooth animations
- ✅ Responsive layouts
- ✅ Dark mode support

---

## 🏗️ Architecture

### **BLoC Pattern (Business Logic Component)**
```
User Input → Event → BLoC → State → UI Update
```

**Implemented BLoCs:**
- `LoginBloc` - Email/password authentication
- `PhoneAuthBloc` - Phone OTP verification
- `MessageBloc` - Chat message handling
- `ProfileBloc` - User profile management
- `PresenceBloc` - Online status tracking

### **Project Structure**
```
lib/
├── core/                   # Shared utilities & services
│   ├── animations/        # Custom animations
│   ├── storage/           # Session management
│   └── theme/             # App theming
├── features/              # Feature modules
│   ├── auth/             # Authentication (Email, Phone, Google)
│   │   ├── login/        # Email/password login
│   │   ├── phone_auth/   # Phone OTP
│   │   ├── signup/       # Registration
│   │   ├── services/     # OAuth services
│   │   └── unified_login/# Unified auth screen
│   ├── chat/             # Messaging
│   │   ├── data/         # Repository & models
│   │   ├── bloc/         # Chat BLoC
│   │   └── ui/           # Chat screens
│   ├── profile/          # User profiles
│   └── presence/         # Real-time presence
└── main.dart             # App entry point
```

---

## 🛠️ Tech Stack

### **Frontend**
- **Flutter** - Cross-platform framework
- **Dart** - Programming language
- **BLoC/Cubit** - State management
- **Material Design** - UI components

### **Backend**
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication
  - File storage
  - Row Level Security (RLS)

### **Key Packages**
```yaml
dependencies:
  flutter_bloc: ^8.1.6          # State management
  supabase_flutter: ^2.9.2      # Backend integration
  google_sign_in: ^6.2.2        # Google OAuth
  country_code_picker: ^3.0.0   # Phone input
  image_picker: ^1.0.7          # Media selection
  video_player: ^2.8.2          # Video playback
  just_audio: ^0.9.36           # Audio playback
  record: ^6.1.2                # Voice recording
  cached_network_image: ^3.3.1 # Image caching
```

---

## 📱 Screenshots

### Authentication Screens
| Email Login | Phone OTP | Google Sign-In |
|------------|-----------|----------------|
| ![Email](docs/screenshots/email.png) | ![Phone](docs/screenshots/phone.png) | ![Google](docs/screenshots/google.png) |

### Chat Interface
| Chat List | Conversation | Media |
|-----------|--------------|-------|
| ![List](docs/screenshots/list.png) | ![Chat](docs/screenshots/chat.png) | ![Media](docs/screenshots/media.png) |

---

## 🔥 Getting Started

### Prerequisites
- Flutter SDK >= 3.32.2
- Dart SDK >= 3.6.0
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/rohitAp007/ProCohat_Training.git
cd supabase_flutter_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**

Create `.env` file:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

Or update `lib/core/config/supabase_config.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

4. **Run the app**
```bash
flutter run
```

---

## 🔧 Configuration

### Authentication Setup

#### **Email/Password**
- Enabled by default in Supabase
- Configure email templates in Supabase Dashboard

#### **Phone OTP**
1. Enable Phone provider in Supabase
2. Add test phone numbers for development:
   - Phone: `7666086414`
   - OTP: `4685`

#### **Google Sign-In**
1. Get OAuth credentials from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google provider in Supabase
3. Update `oauth_service.dart` with Web Client ID

### Database Schema
```sql
-- Apply schema in Supabase SQL Editor
-- See: docs/database/schema.sql

-- Main tables
CREATE TABLE user_profiles (...)
CREATE TABLE conversations (...)
CREATE TABLE messages (...)
CREATE TABLE message_statuses (...)
CREATE TABLE typing_indicators (...)
CREATE TABLE user_presence (...)
```

---

## 📚 Learning Journey - 31 Days

### **What I Learned**

#### **BLoC Architecture** 🏗️
- Event-driven state management
- Separation of business logic from UI
- Testable, maintainable code structure
- Reactive programming with Streams

#### **Real-Time Systems** 📡
- WebSocket connections
- Supabase Realtime subscriptions
- Presence tracking
- Live data synchronization

#### **Authentication** 🔐
- Multi-provider OAuth integration
- Token-based sessions
- Secure password handling
- Phone number validation

#### **Flutter Development** 📱
- Complex widget composition
- Navigation & routing
- State management patterns
- Async programming (Future, Stream)

#### **Database Design** 💾
- Normalized schema design
- Row Level Security (RLS)
- Real-time triggers
- Efficient queries

### **Skills Acquired**
✅ Production-ready app development  
✅ Clean architecture implementation  
✅ Real-time feature integration  
✅ Multi-platform authentication  
✅ Problem-solving & debugging  
✅ Code organization & best practices  

---

## 📊 Project Stats

| Metric | Count |
|--------|-------|
| Features | 15+ |
| BLoCs | 5+ |
| Screens | 10+ |
| Custom Widgets | 30+ |
| Lines of Code | 5,000+ |
| Training Days | 31 |
| Bugs Fixed | 20+ |

---

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release
```

### iOS App
```bash
flutter build ios --release
```

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Test Coverage
```bash
flutter test --coverage
```

### Manual Testing
- Email login: Use any valid Supabase account
- Phone OTP: `7666086414` → OTP: `4685`
- Google: Requires OAuth configuration

---

## 🤝 Contributing

This is a training project, but suggestions are welcome!

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📄 License

This project is for educational purposes.

---

## 👨‍💻 Author

**Rohit Parsode**  
Training Project - ProCohat Company  
Duration: January 1-31, 2026 (31 Days)

### Contact
- GitHub: [@rohitAp007](https://github.com/rohitAp007)
- Project: [ProCohat Training](https://github.com/rohitAp007/ProCohat_Training)

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing framework
- **Supabase** - Powerful backend platform
- **BLoC Library** - Clean state management
- **ProCohat Company** - Training opportunity
- **Open Source Community** - Invaluable resources

---

## 📝 Documentation

- [`TRAINING_SUMMARY.md`](TRAINING_SUMMARY.md) - Complete 31-day training journey
- [`docs/architecture.md`](docs/architecture.md) - Detailed architecture
- [`docs/database/`](docs/database/) - Database schema & migrations
- [`docs/api/`](docs/api/) - API documentation

---

## 🔮 Future Enhancements

- [ ] Voice/Video calls
- [ ] Group chat
- [ ] End-to-end encryption
- [ ] Push notifications
- [ ] Message search
- [ ] Stories feature
- [ ] AI chatbot integration
- [ ] Multi-device sync

---

## ⭐ Features Implemented (Day 31)

### ✅ Completed
- Multi-provider authentication (Email, Phone, Google)
- Real-time messaging
- Media attachments (images, videos, audio)
- Typing indicators (backend)
- Read receipts (backend)
- Online status tracking
- BLoC architecture
- Clean code structure

### ⏳ In Progress
- UI integration for typing indicators
- UI for read receipts
- Message search

---

**Built with ❤️ during 31 days of intensive Flutter training**

**Status**: Production-Ready 🚀  
**Version**: 1.0.0  
**Last Updated**: January 31, 2026
