class User {
  final int id;
  final String username;

  User({
    required this.id,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
    );
  }
}

class AuthResponse {
  final int userId;
  final String username;
  final String token;

  AuthResponse({
    required this.userId,
    required this.username,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      token: json['token'] ?? '',
    );
  }
}

