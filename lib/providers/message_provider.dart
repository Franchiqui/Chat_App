// lib/providers/message_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;
  
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentChatId => _currentChatId;

  void setCurrentChatId(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  Future<void> getChatMessages(String chatId) async {
    _isLoading = true;
    _currentChatId = chatId;
    notifyListeners();

    try {
      _messages = await _messageService.getChatMessages(chatId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String chatId, String currentUserId, String otherUserId, String text) async {
    if (text.trim().isEmpty) return;

    final message = await _messageService.sendTextMessage(chatId, currentUserId, otherUserId, text);
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendFileMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required File file,
    required MessageType tipo,
    String? text,
  }) async {
    final message = await _messageService.sendFileMessage(
      chatId: chatId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      file: file,
      tipo: tipo,
      text: text,
    );
    _messages.add(message);
    notifyListeners();
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _messageService.markMessageAsRead(messageId);
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      _messages[index] = MessageModel(
        id: _messages[index].id,
        texto: _messages[index].texto,
        user1: _messages[index].user1,
        user2: _messages[index].user2,
        idChat: _messages[index].idChat,
        fechaMensaje: _messages[index].fechaMensaje,
        textoBool: _messages[index].textoBool,
        creado: _messages[index].creado,
        displayNameB: _messages[index].displayNameB,
        userId: _messages[index].userId,
        tipo: _messages[index].tipo,
        visto: true,
        filePath: _messages[index].filePath,
        fileName: _messages[index].fileName,
        mensajeUrl: _messages[index].mensajeUrl,
        imagenUrl: _messages[index].imagenUrl,
        mp3Url: _messages[index].mp3Url,
        status: _messages[index].status,
      );
      notifyListeners();
    }
  }

  void addMessage(MessageModel message) {
    if (message.idChat == _currentChatId) {
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        notifyListeners();
      }
    }
  }
}
