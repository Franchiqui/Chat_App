// lib/services/chat_service.dart
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  final PocketBase pb = PocketBaseConfig.pb;

  // Obtener todos los chats del usuario
  Future<List<ChatModel>> getUserChats(String userId) async {
    final resultUser1 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$userId"',
    );
    
    final resultUser2 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user2 = "$userId"',
    );
    
    List<ChatModel> chats = [];
    
    for (var item in resultUser1.items) {
      chats.add(ChatModel.fromJson(item.toJson()));
    }
    
    for (var item in resultUser2.items) {
      chats.add(ChatModel.fromJson(item.toJson()));
    }
    
    return chats;
  }

  // Crear nuevo chat
  Future<ChatModel> createChat(UserModel currentUser, UserModel otherUser) async {
    final now = DateTime.now();
    final fecha = "${now.day}/${now.month}/${now.year}";
    final hora = "${now.hour}:${now.minute}";
    
    final data = {
      'user1': currentUser.id,
      'user2': otherUser.id,
      'displayName_A': currentUser.displayName,
      'displayName_B': otherUser.displayName,
      'fotoUrl_A': currentUser.avatarUrl,
      'fotoUrl_B': otherUser.avatarUrl,
      'fechaChat': fecha,
      'horaChat': hora,
      'ultimoMensaje': '',
    };
    
    final record = await pb.collection(PocketBaseConfig.chatsCollection).create(body: data);
    
    return ChatModel.fromJson(record.toJson());
  }

  // Buscar chat existente entre dos usuarios
  Future<ChatModel?> findChatBetweenUsers(String user1Id, String user2Id) async {
    final result1 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$user1Id" && user2 = "$user2Id"',
    );
    
    if (result1.items.isNotEmpty) {
      return ChatModel.fromJson(result1.items.first.toJson());
    }
    
    final result2 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$user2Id" && user2 = "$user1Id"',
    );
    
    if (result2.items.isNotEmpty) {
      return ChatModel.fromJson(result2.items.first.toJson());
    }
    
    return null;
  }

  // Actualizar último mensaje
  Future<void> updateLastMessage(String chatId, String message) async {
    final now = DateTime.now();
    final fecha = "${now.day}/${now.month}/${now.year}";
    final hora = "${now.hour}:${now.minute}";
    
    await pb.collection(PocketBaseConfig.chatsCollection).update(
      chatId, 
      body: {
        'ultimoMensaje': message,
        'fechaChat': fecha,
        'horaChat': hora,
      },
    );
  }

  // Escuchar cambios en tiempo real para un chat específico
  Future<UnsubscribeFunc> subscribeToChatChanges(String chatId) {
    return pb.collection(PocketBaseConfig.chatsCollection).subscribe('*', (e) {
      ChatModel.fromJson(e.record!.toJson());
    });
  }
}
