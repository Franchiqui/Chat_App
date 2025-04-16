// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatModel> _chats = [];
  bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  Future<void> getUserChats(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _chats = await _chatService.getUserChats(userId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatModel> createChat(UserModel currentUser, UserModel otherUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si ya existe un chat entre estos usuarios
      final existingChat = await _chatService.findChatBetweenUsers(
        currentUser.id,
        otherUser.id,
      );

      if (existingChat != null) {
        if (!_chats.any((chat) => chat.id == existingChat.id)) {
          _chats.add(existingChat);
          notifyListeners();
        }
        return existingChat;
      }

      // Crear nuevo chat
      final chat = await _chatService.createChat(currentUser, otherUser);
      _chats.add(chat);
      notifyListeners();
      return chat;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLastMessage(String chatId, String message) async {
    await _chatService.updateLastMessage(chatId, message);
    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      getUserChats(_chats[index].user1); // Actualizar la lista de chats
    }
  }

  // Obtener un chat por su ID
  ChatModel? getChatById(String chatId) {
  return _chats.firstWhereOrNull((chat) => chat.id == chatId);
}
}