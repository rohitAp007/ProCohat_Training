# ProCohat Training - Flutter Supabase App

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5.0-blue.svg)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-2.0.0-green.svg)](https://supabase.com/)
[![BLoC](https://img.shields.io/badge/BLoC-9.0.0-orange.svg)](https://bloclibrary.dev/)

> A production-ready Flutter authentication app built with BLoC pattern and Supabase backend. Created as part of the ProCohat 30-day Flutter training program.

---

## ✨ Features

### Implemented (Days 1-7)
- ✅ **Email/Password Authentication** - Full login/signup flow
- ✅ **Password Reset** - Email-based password recovery
- ✅ **Session Management** - Persistent login with `shared_preferences`
- ✅ **Real-time Validation** - Instant email/password feedback
- ✅ **Error Handling** - Type-safe exceptions with user-friendly messages
- ✅ **Smooth Animations** - 60 FPS page transitions and micro-animations
- ✅ **Professional UI** - Material 3 design with polished aesthetics
- ✅ **Comprehensive Testing** - 21 unit tests (validators + BLoC)
- ✅ **Clean Architecture** - 3-layer separation (UI, BLoC, Data)

### Coming Soon (Days 8-30)
- 🔜 Social Authentication (Google, Apple, GitHub)
- 🔜 User Profiles & CRUD operations
- 🔜 Real-time features with Supabase
- 🔜 Offline support & local database
- 🔜 Performance optimizations
- 🔜 Production deployment

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK**: 3.24.0 or higher ([Install](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: 3.5.0 or higher (comes with Flutter)
- **Editor**: VS Code or Android Studio
- **Supabase Account**: Free tier ([Sign up](https://supabase.com))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/supabase_flutter_app.git
   cd supabase_flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Create a `lib/core/config/supabase_config.dart` file:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```
   
   Or use environment variables (recommended for production).

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/features/auth/login/bloc/login_bloc_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Current Test Coverage
- **Total Tests**: 21 passing
- **Validators**: 13 tests
- **LoginBloc**: 8 tests
- **Coverage**: ~80% for core features

---

## 📁 Project Structure

```
lib/
├── core/                  # Shared utilities
│   ├── animations/        # Reusable animations
│   ├── auth/              # Auth state management
│   ├── constants/         # App constants
│   ├── error/             # Error handling
│   ├── storage/           # Local storage
│   ├── theme/             # App theming
│   ├── utils/             # Utilities
│   └── widgets/           # Reusable widgets
├── features/              # Feature modules
│   ├── auth/              # Authentication
│   │   ├── data/          # Repository & exceptions
│   │   ├── login/         # Login feature
│   │   ├── signup/        # Signup feature
│   │   ├── password_reset/# Password reset
│   │   └── home/          # Home screen
│   └── splash/            # Splash screen
├── app.dart               # App widget
└── main.dart              # Entry point

test/                      # Tests mirror lib/ structure
docs/                      # Documentation
```

See [Architecture Documentation](docs/architecture.md) for detailed explanation.

---

## 🏗️ Architecture

### BLoC Pattern

```
User Action → Event → BLoC → State → UI Update
```

**Benefits:**
- Separation of concerns
- Testable business logic
- Predictable state management
- Excellent developer tools

### Clean Architecture

```
Presentation (UI)
    ↓
BLoC (Business Logic)
    ↓
Data (Repository)
```

**Why?**
- Independent layers
- Easy to test
- Maintainable
- Scalable

Read the full [Architecture Guide](docs/architecture.md).

---

## 🎨 Key Technologies

### State Management
- **flutter_bloc** - BLoC pattern implementation
- **equatable** - Value equality for states

### Backend
- **supabase_flutter** - Supabase client
- **PostgreSQL** - Database (via Supabase)

### Testing
- **bloc_test** - BLoC testing utilities
- **mocktail** - Mocking framework

### UI/UX
- **Material 3** - Google's design system
- Custom animations & transitions

---

## 📖 Documentation

- [Architecture Documentation](docs/architecture.md) - System design & patterns
- [Error Codes Reference](docs/error_codes.md) - Complete error code guide
- [API Documentation](docs/api.md) - Backend API reference *(coming soon)*
- [Contributing Guide](CONTRIBUTING.md) - How to contribute *(coming soon)*

---

## 🧑‍💻 Development

### Code Style

We follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide.

**Key principles:**
- Clear, descriptive names
- Single responsibility
- DRY (Don't Repeat Yourself)
- Comprehensive documentation

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/your-feature
```

**Commit Convention:**  
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `refactor:` Code refactoring

---

## 🤝 Contributing

This is a training project, but contributions and suggestions are welcome!

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📝 License

This project is created for educational purposes as part of ProCohat training program.

---

## 🙏 Acknowledgments

- **ProCohat Team** - Training program & guidance
- **Flutter Team** - Excellent framework
- **BLoC Library** - State management solution
- **Supabase** - Backend-as-a-Service platform

---

## 📧 Contact

**Developer**: Your Name  
**Email**: your.email@example.com  
**LinkedIn**: [Your LinkedIn](https://linkedin.com/in/yourprofile)  
**GitHub**: [@yourusername](https://github.com/yourusername)

---

## 📊 Training Progress

**Current Status**: Day 7 of 30

| Week | Focus | Status |
|------|-------|--------|
| Week 1 | Auth Foundation | ✅ Complete |
| Week 2 | CRUD Operations | 🔜 Upcoming |
| Week 3 | Real-time Features | 🔜 Upcoming |
| Week 4 | Polish & Deploy | 🔜 Upcoming |

---

## 🎯 Learning Outcomes

Through this project, you'll master:
- ✅ BLoC state management pattern
- ✅ Clean architecture principles
- ✅ Repository pattern
- ✅ Comprehensive testing (unit, widget, integration)
- ✅ Supabase integration
- ✅ Professional error handling
- ✅ Modern UI/UX design
- ✅ Git workflow & best practices

---

**Happy Coding!** 🚀

*Built with ❤️ using Flutter*
