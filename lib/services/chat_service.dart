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

  /// Limpia chats duplicados entre dos usuarios, dejando solo el más reciente
  Future<void> cleanDuplicateChats(String user1Id, String user2Id) async {
    // Busca todos los chats entre ambos usuarios (en ambos órdenes)
    final result1 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$user1Id" && user2 = "$user2Id"',
      sort: '-created',
    );
    final result2 = await pb.collection(PocketBaseConfig.chatsCollection).getList(
      filter: 'user1 = "$user2Id" && user2 = "$user1Id"',
      sort: '-created',
    );
    final allChats = [...result1.items, ...result2.items];
    if (allChats.length > 1) {
      // Mantener solo el más reciente
      final chatsSorted = List.from(allChats)
        ..sort((a, b) => b.created.compareTo(a.created));
      final keepChat = chatsSorted.first;
      final toDelete = chatsSorted.skip(1);
      for (final chat in toDelete) {
        try {
          await pb.collection(PocketBaseConfig.chatsCollection).delete(chat.id);
          print('[CLEANUP] Chat duplicado eliminado: ${chat.id}');
        } catch (e) {
          print('[CLEANUP] Error eliminando chat duplicado: $e');
        }
      }
      print('[CLEANUP] Solo se mantiene el chat: ${keepChat.id}');
    } else {
      print('[CLEANUP] No hay duplicados entre $user1Id y $user2Id');
    }
  }

  // Crear nuevo chat (mejorado para evitar duplicados)
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
    print('[DEBUG][ChatService] Datos enviados a PocketBase:');
    print(data);
    // Antes de crear, limpia duplicados
    await cleanDuplicateChats(currentUser.id, otherUser.id);
    // Vuelve a buscar si quedó solo uno
    final existing = await findChatBetweenUsers(currentUser.id, otherUser.id);
    if (existing != null) {
      print('[DEBUG][ChatService] Ya existe chat tras limpieza: ${existing.id}');
      return existing;
    }
    final record = await pb.collection(PocketBaseConfig.chatsCollection).create(body: data);
    print('[DEBUG][ChatService] Registro creado PocketBase:');
    print(record.toJson());
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