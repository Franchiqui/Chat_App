// lib/providers/message_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/message_service.dart' as msg_service;
import '../services/message_service_audio.dart' as msg_audio_service;
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';

class MessageProvider with ChangeNotifier {
  final msg_service.MessageService _messageService =
      msg_service.MessageService();
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
    print('[MessageProvider] getChatMessages: chatId=$_currentChatId');
    notifyListeners();

    try {
      _messages = await _messageService.getChatMessages(chatId);
      print(
          '[MessageProvider] Mensajes cargados (${_messages.length}): ${_messages.map((m) => m.id).toList()}');
      notifyListeners();
      print('[MessageProvider] notifyListeners después de cargar mensajes');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[MessageProvider] notifyListeners después de isLoading=false');
    }
  }

  Future<void> sendTextMessage(String chatId, String currentUserId,
      String otherUserId, String text) async {
    if (text.trim().isEmpty) return;

    final message = await _messageService.sendTextMessage(
        chatId, currentUserId, otherUserId, text);
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendFileMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required dynamic file, // File o Uint8List
    required MessageType tipo,
    String? text,
    String? fileName, // para web
    BuildContext? context, // Para feedback visual
  }) async {
    try {
      final message = await _messageService.sendFileMessage(
        chatId: chatId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        file: file,
        tipo: tipo,
        text: text,
        fileName: fileName,
      );
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar archivo: ' + e.toString())),
        );
      }
      rethrow;
    }
  }

  /// Envía un mensaje de audio grabado desde bytes (web y móvil)
  Future<void> sendAudioBytesMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required Uint8List audioBytes,
    required String fileName,
    String? text,
  }) async {
    final message =
        await msg_audio_service.MessageService().sendAudioBytesMessage(
      chatId: chatId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      audioBytes: audioBytes,
      fileName: fileName,
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
        senderAvatar: _messages[index].senderAvatar,
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

  Future<void> addMessage(MessageModel message) async {
    print(
        '[MessageProvider] addMessage: idChat=[36m${message.idChat}[0m, currentChatId=$_currentChatId, id=${message.id}');
    if (message.idChat == _currentChatId) {
      if (!_messages.any((m) => m.id == message.id)) {
        // Obtener el mensaje expandido desde PocketBase
        try {
          final pb = _messageService.pb;
          final record = await pb
              .collection(PocketBaseConfig.messagesCollection)
              .getOne(message.id, expand: 'user1,user2');
          final expandedMessage = MessageModel.fromJson(record.toJson());
          _messages.add(expandedMessage);
          print(
              '[MessageProvider] Mensaje expandido agregado (${expandedMessage.id}). Total ahora: ${_messages.length}');
          notifyListeners();
          print('[MessageProvider] notifyListeners después de addMessage');
        } catch (e) {
          print('[MessageProvider] Error al expandir mensaje: $e');
          // Si falla, agrega el mensaje plano
          _messages.add(message);
          notifyListeners();
        }
      } else {
        print(
            '[MessageProvider] Mensaje duplicado, no se agrega (${message.id})');
      }
    } else {
      print(
          '[MessageProvider] Mensaje ignorado: idChat=${message.idChat} != $_currentChatId');
    }
  }
}
