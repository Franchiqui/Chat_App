// lib/services/auth_service.dart
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final PocketBase pb = PocketBaseConfig.pb;

  // Obtener usuario actual
  UserModel? getCurrentUser() {
    if (pb.authStore.isValid) {
      final userData = pb.authStore.model;
      return UserModel(
        id: userData.id,
        username: userData.username,
        displayName: userData.data['displayName_A'] ?? userData.username,
        avatarUrl: userData.data['avatar'],
      );
    }
    return null;
  }

  // Registrar usuario
  Future<UserModel> register(String username, String password, String displayName) async {
    final authData = await pb.collection(PocketBaseConfig.usersCollection).create(body: {
      'username': username,
      'password': password,
      'passwordConfirm': password,
      'displayName_A': displayName,
    });
    
    return UserModel(
      id: authData.id,
      username: username,
      displayName: displayName,
    );
  }

  // Iniciar sesión
  Future<UserModel> login(String username, String password) async {
    final authData = await pb.collection(PocketBaseConfig.usersCollection).authWithPassword(
      username,
      password,
    );
    
    return UserModel(
      id: authData.record.id,
      username: username,
      displayName: authData.record.data['displayName_A'] ?? username,
      avatarUrl: authData.record.data['avatar'],
    );
  }

  // Cerrar sesión
  Future<void> logout() async {
    pb.authStore.clear();
  }

  // Actualizar perfil
  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data) async {
    final record = await pb.collection(PocketBaseConfig.usersCollection).update(userId, body: data);
    
    return UserModel(
      id: record.id,
      username: record.data['username'],
      displayName: record.data['displayName_A'] ?? record.data['username'],
      avatarUrl: record.data['avatar'],
    );
  }
}
