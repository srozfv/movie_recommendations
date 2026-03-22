// Модель пользователя (получается от бэкенда)
class User {
  final int id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final bool? isOnboarded;

  User({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.isOnboarded,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      isOnboarded: json['isOnboarded'],
    );
  }
}

// Запрос на регистрацию (отправляется на бэкенд)
class RegisterRequest {
  final String username;
  final String email;
  final String password;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };
}

// Запрос на вход (отправляется на бэкенд)
class LoginRequest {
  final String username; // должно быть username, а не email
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}