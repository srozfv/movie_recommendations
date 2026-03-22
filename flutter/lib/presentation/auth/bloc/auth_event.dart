part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String email;
  final String password;
  LoggedIn(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  RegisterRequested(this.username, this.email, this.password);
}

class LoggedOut extends AuthEvent {}