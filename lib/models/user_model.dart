// En user_model.dart
class UserModel {
  final String id;
  final String username;
  final String displayName_A; // No puede ser null
  final String? avatar; // Puede ser null (opcional)

  UserModel({
    required this.id,
    required this.username,
    required this.displayName_A,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String, // Valor predeterminado si es null
      username: json['username'] as String,
      displayName_A: json['displayName_A'] as String,
      avatar: json['avatar'],
    );
  }
}