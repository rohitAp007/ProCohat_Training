import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_event.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_state.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock class for AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock class for Supabase User
class MockUser extends Mock implements User {}

void main() {
  group('LoginBloc', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    test('initial state is LoginInitial', () {
      final bloc = LoginBloc(authRepository: mockAuthRepository);
      expect(bloc.state, isA<LoginInitial>());
      bloc.close();
    });

    group('LoginEmailChanged', () {
      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with valid email',
        build: () => LoginBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const LoginEmailChanged('test@example.com')),
        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.email, 'email', 'test@example.com')
              .having((s) => s.isEmailValid, 'isEmailValid', true),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with invalid email',
        build: () => LoginBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const LoginEmailChanged('invalid-email')),
        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.email, 'email', 'invalid-email')
              .having((s) => s.isEmailValid, 'isEmailValid', false),
        ],
      );
    });

    group('LoginPasswordChanged', () {
      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with valid password',
        build: () => LoginBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const LoginPasswordChanged('password123')),
        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.password, 'password', 'password123')
              .having((s) => s.isPasswordValid, 'isPasswordValid', true),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with invalid password (too short)',
        build: () => LoginBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const LoginPasswordChanged('12345')),
        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.password, 'password', '12345')
              .having((s) => s.isPasswordValid, 'isPasswordValid', false),
        ],
      );
    });

    group('LoginSubmitted', () {
      final mockUser = MockUser();

      blocTest<LoginBloc, LoginState>(
        'emits [LoginInProgress, LoginSuccess] when login succeeds',
        setUp: () {
          when(() => mockAuthRepository.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => mockUser);
        },
        build: () => LoginBloc(authRepository: mockAuthRepository),
        seed: () => const LoginEditing(
          email: 'test@example.com',
          password: 'password123',
          isEmailValid: true,
          isPasswordValid: true,
        ),
        act: (bloc) => bloc.add(const LoginSubmitted()),
        expect: () => [
          isA<LoginInProgress>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<LoginSuccess>().having((s) => s.isSuccess, 'isSuccess', true),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signInWithEmail(
                email: 'test@example.com',
                password: 'password123',
              )).called(1);
        },
      );

      blocTest<LoginBloc, LoginState>(
        'emits [LoginInProgress, LoginFailure] when login fails with invalid credentials',
        setUp: () {
          when(() => mockAuthRepository.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(InvalidCredentialsException());
        },
        build: () => LoginBloc(authRepository: mockAuthRepository),
        seed: () => const LoginEditing(
          email: 'test@example.com',
          password: 'wrongpassword',
          isEmailValid: true,
          isPasswordValid: true,
        ),
        act: (bloc) => bloc.add(const LoginSubmitted()),
        expect: () => [
          isA<LoginInProgress>(),
          isA<LoginFailure>()
              .having((s) => s.errorMessage, 'errorMessage',
                  contains('Invalid email or password')),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'does not emit any state when form is invalid',
        build: () => LoginBloc(authRepository: mockAuthRepository),
        seed: () => const LoginEditing(
          email: 'invalid',
          password: '123',
          isEmailValid: false,
          isPasswordValid: false,
        ),
        act: (bloc) => bloc.add(const LoginSubmitted()),
        expect: () => [],
      );
    });
  });
}
