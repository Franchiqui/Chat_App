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

  // En lib/services/auth_service.dart

Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  try {
    if (query.isEmpty) return [];
    final results = await pb.collection('users').getList(
      page: 1,
      perPage: 10,
      filter: 'username ~ "$query" || displayName_A ~ "$query"',
    );
    List<Map<String, dynamic>> users = [];
    for (var item in results.items) {
      if (item.id != pb.authStore.model?.id) {
        users.add({
          'id': item.id,
          'username': item.data['username'],
          'displayName': item.data['displayName_A'] ?? item.data['username'],
          'avatar': item.data['avatar'] ?? '',
        });
      }
    }
    print('Usuarios encontrados: $users'); // Depuración
    return users;
  } catch (e) {
    print('Error al buscar usuarios: $e');
    return [];
  }
}

}
