// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    // Verificar si hay un usuario autenticado al iniciar
    _initializeAuth();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = _authService.getCurrentUser();
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.register(username, password, displayName);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // auth_provider.dart
Future<void> login(String username, String password) async {
  _isLoading = true;
  notifyListeners();

  try {
    final user = await _authService.login(username, password);
    _user = user;
  } catch (e) {
    throw Exception('Error: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
  
}

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(_user!.id, data);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // En lib/providers/auth_provider.dart

Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  try {
    final results = await _authService.searchUsers(query);
    return results;
  } catch (e) {
    return [];
  }
}

}
