// lib/models/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName_A'] ?? json['username'],
      avatarUrl: json['avatar'],
    );
  }
}
