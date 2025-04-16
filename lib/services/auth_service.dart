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
        displayName_A: userData.data['displayName_A'] ?? userData.username,
        avatar: userData.data['avatar'],
      );
    }
    return null;
  }

  // Registrar usuario
  // En auth_service.dart
  Future<UserModel> register(
      String username, String password, String displayName) async {
    final authData = await pb.collection('users').create(body: {
      'username': username,
      'password': password,
      'passwordConfirm': password,
      'displayName_A': displayName, // Campo obligatorio
      'avatar': '', // Campo opcional
    });

    return UserModel.fromJson(authData.data);
  }

  // Iniciar sesión
  Future<UserModel> login(String username, String password) async {
    try {
      // Autenticar al usuario
      final authData = await pb
          .collection(PocketBaseConfig.usersCollection)
          .authWithPassword(username, password);

      // Validar que el usuario y sus campos existan
      if (authData.record.data['id'] == null ||
          authData.record.data['username'] == null) {
        throw Exception('Datos del usuario incompletos');
      }

      // Crear y devolver el modelo de usuario
      return UserModel(
        id: authData.record.id,
        username: authData.record.data['username'],
        displayName_A: authData.record.data['displayName_A'] ??
            authData.record.data['username'],
        avatar: authData.record.data['avatar'],
      );
    } catch (e) {
      throw Exception('Error en el login: $e');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    pb.authStore.clear();
  }

  // Actualizar perfil
  Future<UserModel> updateProfile(
      String userId, Map<String, dynamic> data) async {
    final record = await pb
        .collection(PocketBaseConfig.usersCollection)
        .update(userId, body: data);

    return UserModel(
      id: record.id,
      username: record.data['username'],
      displayName_A: record.data['displayName_A'] ?? record.data['username'],
      avatar: record.data['avatar'],
    );
  }

  // En lib/services/auth_service.dart

// En auth_service.dart
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Si la consulta está vacía, devolver todos los usuarios (excepto el actual)
      String filter = '';
      if (query.isEmpty) {
        filter = 'id != "${pb.authStore.model?.id}"';
      } else {
        filter =
            '(username ~ "$query" || displayName_A ~ "$query") && id != "${pb.authStore.model?.id}"';
      }

      final results =
          await pb.collection(PocketBaseConfig.usersCollection).getList(
                page: 1,
                perPage: 20,
                filter: filter,
              );

      List<Map<String, dynamic>> users = [];
      for (var item in results.items) {
        final String displayName =
            item.data['displayName_A'] ?? item.data['username'] ?? 'Usuario';
        final String username = item.data['username'] ?? '';

        users.add({
          'id': item.id,
          'username': username,
          'displayName': displayName,
          'avatar': item.data['avatar'],
        });
      }

      return users;
    } catch (e) {
      print('Error al buscar usuarios: $e');
      // Devolver una lista vacía en caso de error
      return [];
    }
  }
}
