import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<UserModel> _usuarios = [];
  bool _isLoading = false;

  List<UserModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;

  Future<void> cargarUsuarios() async {
    _isLoading = true;
    notifyListeners();
    try {
      _usuarios = await _userService.getAllUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
