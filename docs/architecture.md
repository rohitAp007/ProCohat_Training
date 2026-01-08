# Architecture Documentation

## 📐 ProCohat Training App - Authentication System

### Overview
This Flutter app demonstrates production-ready authentication using **BLoC pattern** for state management and **Supabase** as the backend. Built with clean architecture principles for maintainability and testability.

---

## 🏗️ Architecture Pattern

### Clean Architecture (3 Layers)

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Widgets, Screens, BlocBuilders)   │
│                                         │
│  Responsibilities:                      │
│  - Display data to user                 │
│  - Capture user interactions            │
│  - Dispatch events to BLoC              │
│  - React to state changes               │
└──────────────┬──────────────────────────┘
               ↓ Events
               ↑ States
┌──────────────┴──────────────────────────┐
│            BLOC LAYER                   │
│  (Business Logic Components)            │
│                                         │
│  Responsibilities:                      │
│  - Process events                       │
│  - Apply business logic                 │
│  - Call repository methods              │
│  - Emit states                          │
│  - NO UI knowledge                      │
└──────────────┬──────────────────────────┘
               ↓ Method Calls
               ↑ Data / Exceptions
┌──────────────┴──────────────────────────┐
│           DATA LAYER                    │
│  (Repository, API, Local Storage)       │
│                                         │
│  Responsibilities:                      │
│  - Communicate with Supabase            │
│  - Handle API calls                     │
│  - Manage local storage                 │
│  - Transform raw data to models         │
│  - NO business logic                    │
└─────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
lib/
├── core/                          # Shared across features
│   ├── animations/                # Reusable animations
│   │   ├── fade_in_widget.dart
│   │   ├── slide_in_widget.dart
│   │   └── page_transitions.dart
│   ├── auth/                      # Auth state management
│   │   └── auth_state_manager.dart
│   ├── constants/                 # App-wide constants
│   │   ├── app_spacing.dart
│   │   └── app_icons.dart
│   ├── error/                     # Error handling
│   │   ├── error_codes.dart
│   │   ├── error_handler.dart
│   │   └── error_screen.dart
│   ├── storage/                   # Local storage
│   │   └── session_manager.dart
│   ├── theme/                     # App theming
│   │   └── app_theme.dart
│   ├── utils/                     # Utility functions
│   │   └── validators.dart
│   └── widgets/                   # Reusable widgets
│       ├── custom_snackbar.dart
│       └── loading_overlay.dart
│
├── features/                      # Feature modules
│   ├── auth/                      # Authentication feature
│   │   ├── data/                  # Data layer
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_exceptions.dart
│   │   ├── home/                  # Home screen
│   │   │   └── home_screen.dart
│   │   ├── login/                 # Login feature
│   │   │   ├── bloc/
│   │   │   │   ├── login_bloc.dart
│   │   │   │   ├── login_event.dart
│   │   │   │   └── login_state.dart
│   │   │   ├── ui/
│   │   │   │   └── login_screen.dart
│   │   │   └── widgets/
│   │   │       └── login_form.dart
│   │   ├── password_reset/        # Password reset
│   │   │   ├── bloc/
│   │   │   ├── ui/
│   │   │   └── widgets/
│   │   ├── signup/                # Signup feature
│   │   │   ├── bloc/
│   │   │   ├── ui/
│   │   │   └── widgets/
│   │   └── widgets/               # Shared auth widgets
│   │       └── auth_wrapper.dart
│   └── splash/                    # Splash screen
│       └── splash_screen.dart
│
├── app.dart                       # App widget
└── main.dart                      # Entry point

test/                              # Mirror of lib/ structure
├── core/
│   └── utils/
│       └── validators_test.dart
└── features/
    └── auth/
        └── login/
            └── bloc/
                └── login_bloc_test.dart
```

---

## 🔄 Data Flow

### Complete User Journey Example: Login

```
1. USER INTERACTION
   User types email → TextField.onChanged()

2. EVENT CREATION & DISPATCH
   LoginEmailChanged(email) created
   context.read<LoginBloc>().add(event)

3. BLOC RECEIVES EVENT
   on<LoginEmailChanged>() handler triggered

4. BUSINESS LOGIC
   - Validate email format
   - Check requirements
   - Prepare new state

5. EMIT STATE
   emit(LoginEditing(email: ..., isEmailValid: ...))

6. UI UPDATE
   BlocBuilder rebuilds
   Shows validation feedback

7. USER SUBMITS
   LoginSubmitted() event fired

8. BLOC CALLS REPOSITORY
   repository.signInWithEmail(email, password)

9. REPOSITORY → API
   Supabase signInWithPassword()

10. API RESPONSE
    Success or Error

11. REPOSITORY HANDLES RESPONSE
    Returns User or throws Exception

12. BLOC EMITS FINAL STATE
    Success → LoginSuccess(user)
    Error → LoginFailure(errorMessage)

13. UI REACTS
    Success → Navigate to HomeScreen
    Error → Show error message
```

---

## 🧩 Key Components Explained

### 1. BLoC (Business Logic Component)

**Purpose**: Manage state and business logic

**Example: LoginBloc**
```dart
Events:                    States:
- LoginEmailChanged    →   - LoginInitial
- LoginPasswordChanged →   - LoginEditing
- LoginSubmitted       →   - LoginInProgress
                           - LoginSuccess
                           - LoginFailure
```

**Why BLoC?**
- Separates UI from logic
- Testable (can test logic without UI)
- Predictable state changes
- Powerful dev tools

### 2. Repository Pattern

**Purpose**: Abstract data sources

**Benefits:**
- BLoC doesn't know about Supabase
- Easy to test (mock repository)
- Swap backends easily
- Centralized data logic

**AuthRepository Methods:**
```dart
signInWithEmail()     // Login
signUpWithEmail()     // Register
signOut()             // Logout
getCurrentUser()      // Get current user
resetPassword()       // Password reset
authStateChanges()    // Listen to auth events
```

### 3. Custom Exceptions

**Purpose**: Type-safe error handling

**Hierarchy:**
```
AppAuthException (base)
├── InvalidCredentialsException
├── EmailAlreadyInUseException
├── NetworkException
├── EmailNotConfirmedException
└── UnknownAuthException
```

**Benefits:**
- Specific error handling
- User-friendly messages
- Error codes for tracking
- Recovery suggestions

### 4. State Management Flow

**Immutable States + Equatable:**
```dart
class LoginEditing extends LoginState {
  final String email;
  final bool isEmailValid;
  
  // Immutable - create new instance to "change"
  const LoginEditing({required this.email, required this.isEmailValid});
  
  // Equatable - compare by values
  @override
  List<Object?> get props => [email, isEmailValid];
}
```

**Why Immutable?**
- Predictable (state can't change unexpectedly)
- Debuggable (state history trackable)
- Performance (Flutter optimizes rebuilds)

---

## 🎨 UI/UX Architecture

### Material 3 Theme System

**Defined in:** `lib/core/theme/app_theme.dart`

**Features:**
- Light theme (primary blue)
- Consistent colors
- Typography scale
- Component themes
- Border radius (12px standard)

### Animation System

**Components:**
1. **Page Transitions** - Fade, slide, scale routes
2. **Micro-Animations** - FadeInWidget, SlideInWidget
3. **Loading States** - Skeleton screens, spinners

**Philosophy:** 60 FPS smooth, 300ms duration, easing curves

### Responsive Design

**Approach:**
- Constraints-based layouts
- MediaQuery for screen dimensions
- Max width for forms (400px)
- Spacing system (xs to xxl)

---

## 🔐 Authentication Flow

### Registration (Sign Up)

```
User fills form
    ↓
SignupBloc validates
    ↓
SignupSubmitted event
    ↓
AuthRepository.signUpWithEmail()
    ↓
Supabase creates account
    ↓
Email verification sent (if enabled)
    ↓
SignupSuccess emitted
    ↓
Navigate to login or home
```

### Login (Sign In)

```
User enters credentials
    ↓
LoginBloc validates
    ↓
LoginSubmitted event
    ↓
AuthRepository.signInWithEmail()
    ↓
Supabase authenticates
    ↓
SessionManager saves preference
    ↓
AuthStateManager updates
    ↓
LoginSuccess emitted
    ↓
Navigate to HomeScreen
```

### Persistent Login

```
App launches
    ↓
SplashScreen shown
    ↓
AuthStateManager checks session
    ↓
Supabase getCurrentUser()
    ↓
If user exists:
  → Navigate to HomeScreen
Else:
  → Navigate to LoginScreen
```

### Password Reset

```
User enters email
    ↓
PasswordResetBloc validates
    ↓
AuthRepository.resetPassword()
    ↓
Supabase sends reset email
    ↓
User clicks link
    ↓
Redirected to update password
```

---

## 🧪 Testing Strategy

### Test Pyramid

```
        /\
       /  \      E2E Tests (planned)
      /────\
     /      \    Integration Tests (planned)
    /────────\
   /          \  Unit Tests (implemented)
  /────────────\
     21 Tests
```

### Current Test Coverage

**Validators (13 tests):**
- Email validation (6 tests)
- Password strength (4 tests)
- Strong password check (3 tests)

**LoginBloc (8 tests):**
- Initial state
- Email/password changes
- Successful login
- Error scenarios
- Form validation

### Mocking Strategy

**Tools:** `mocktail` package

**What We Mock:**
- AuthRepository (in BLoC tests)
- Supabase User

**Why Mock:**
- Tests run fast
- No real API calls
- Predictable results
- Test error scenarios easily

---

## 📊 State Management Patterns

### 1. Event-Driven Architecture

**User Action → Event → BLoC  → State → UI**

### 2. Unidirectional Data Flow

Data flows one way: down (from BLoC to UI)  
Events flow up (from UI to BLoC)

### 3. Single Source of Truth

BLoC holds current state  
UI is derived from state  
No UI-level state for business logic

---

## 🔧 Design Decisions

### Why BLoC over Provider/Riverpod?

**Chosen: BLoC**
- Industry standard
- Excellent testing support
- Clear event-state pattern
- Powerful dev tools
- Good for complex flows

### Why Repository Pattern?

**Benefits:**
- Abstraction layer
- Testability
- Flexibility (swap Supabase for Firebase)
- Single responsibility

### Why Supabase?

**Advantages:**
- Open source
- PostgreSQL-based
- Real-time capabilities
- Easy authentication
- Free tier generous

### Why Clean Architecture?

**Benefits:**
- Separation of concerns
- Independent layers
- Testable
- Maintainable
- Scalable

---

## 🚀 Performance Considerations

### Optimizations Implemented

1. **Const Constructors** - Compile-time constants
2. **Equatable** - Prevent unnecessary rebuilds
3. **Lazy Loading** - Load resources when needed
4. **Dispose Pattern** - Clean up resources
5. **Async/Await** - Non-blocking operations

### Future Optimizations

- Image caching
- API response caching
- Debouncing search/validation
- Pagination for lists

---

## 🔒 Security Practices

### Implemented

1. **No Hardcoded Secrets** - Use environment variables (planned)
2. **Password Validation** - Client-side checks
3. **Email Trimming** - Prevent whitespace issues
4. **HTTPS Only** - Supabase enforces
5. **Exception Handling** - No sensitive data in errors

### Planned

- Rate limiting
- Input sanitization
- Two-factor authentication
- Session timeout

---

## 📚 Dependencies

### Production

```yaml
flutter_bloc: ^9.0.0      # State management
supabase_flutter: ^2.0.0  # Backend/Auth
equatable: ^2.0.5         # Value equality
intl: ^0.19.0             # Internationalization
shared_preferences: ^2.3.4 # Local storage
connectivity_plus: ^6.0.0 # Network status
```

### Development

```yaml
bloc_test: ^10.0.0        # BLoC testing
mocktail: ^1.0.4          # Mocking
flutter_test: SDK         # Testing framework
```

---

## 🔄 Future Enhancements

### Planned Features (Days 8-30)

1. **CRUD Operations** - User profiles, data management
2. **Real-time Features** - Notifications, live updates
3. **Advanced UI** - Complex forms, data visualization
4. **Offline Support** - Local database, sync
5. **Performance** - Optimizations, caching
6. **Production Polish** - Error boundaries, analytics

---

## 📖 Learning Resources

### Official Docs
- [Flutter Docs](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev)
- [Supabase Docs](https://supabase.com/docs)

### Key Patterns
- Clean Architecture
- Repository Pattern
- BLoC Pattern
- SOLID Principles

---

## 🎯 Summary

This app demonstrates:
✅ Clean architecture
✅ BLoC state management
✅ Repository pattern  
✅ Comprehensive testing
✅ Professional error handling
✅ Smooth animations
✅ Production-ready code quality

**Philosophy:** Build to learn, learn to build better.

---

*Last Updated: January 7, 2026*  
*Version: 1.0.0*  
*Training Progress: Day 7 of 30*
