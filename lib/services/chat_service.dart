// lib/services/chat_service.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  final PocketBase pb = PocketBaseConfig.pb;

  // Obtener todos los chats del usuario
  Future<List<ChatModel>> getUserChats(String userId) async {
  try {
    final List<ChatModel> chats = [];
    
    // Buscar chats donde el usuario actual es user1
    final resultUser1 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$userId"',
      sort: '-horaChat', // Ordenar por hora del último mensaje
      expand: 'user1,user2', // Expandir datos de usuarios
    );
    
    // Buscar chats donde el usuario actual es user2
    final resultUser2 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user2 = "$userId"',
      sort: '-horaChat', // Ordenar por hora del último mensaje
      expand: 'user1,user2', // Expandir datos de usuarios
    );
    
    // Convertir resultados a modelos de chat
    for (var item in resultUser1.items) {
      chats.add(ChatModel.fromJson(item.toJson()));
    }
    for (var item in resultUser2.items) {
      chats.add(ChatModel.fromJson(item.toJson()));
    }
    
    // Ordenar por la hora del último mensaje (más reciente primero)
    chats.sort((a, b) {
      if (a.fechaChat == null || b.fechaChat == null) return 0;
      if (a.horaChat == null || b.horaChat == null) return 0;
      
      final aParts = a.fechaChat!.split('/');
      final bParts = b.fechaChat!.split('/');
      
      if (aParts.length != 3 || bParts.length != 3) return 0;
      
      final aDate = DateTime(
        int.parse(aParts[2]), // año
        int.parse(aParts[1]), // mes
        int.parse(aParts[0]), // día
      );
      
      final bDate = DateTime(
        int.parse(bParts[2]), // año
        int.parse(bParts[1]), // mes
        int.parse(bParts[0]), // día
      );
      
      final aTimeParts = a.horaChat!.split(':');
      final bTimeParts = b.horaChat!.split(':');
      
      if (aTimeParts.length != 2 || bTimeParts.length != 2) return 0;
      
      final aTime = TimeOfDay(
        hour: int.parse(aTimeParts[0]),
        minute: int.parse(aTimeParts[1]),
      );
      
      final bTime = TimeOfDay(
        hour: int.parse(bTimeParts[0]),
        minute: int.parse(bTimeParts[1]),
      );
      
      final aDateTime = DateTime(
        aDate.year,
        aDate.month,
        aDate.day,
        aTime.hour,
        aTime.minute,
      );
      
      final bDateTime = DateTime(
        bDate.year,
        bDate.month,
        bDate.day,
        bTime.hour,
        bTime.minute,
      );
      
      return bDateTime.compareTo(aDateTime); // Orden descendente
    });
    
    return chats;
  } catch (e) {
    print('Error al obtener chats: $e');
    return [];
  }
}

  // Crear nuevo chat
  Future<ChatModel> createChat(UserModel currentUser, UserModel otherUser) async {
    final now = DateTime.now();
    final fecha = "${now.day}/${now.month}/${now.year}";
    final hora = "${now.hour}:${now.minute}";
    final data = {
      'user1': currentUser.id,
      'user2': otherUser.id,
      'displayName_A': currentUser.displayName_A,
      'displayName_B': otherUser.displayName_A,
      'fotoUrl_A': currentUser.avatar,
      'fotoUrl_B': otherUser.avatar,
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