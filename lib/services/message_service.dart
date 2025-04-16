// lib/services/message_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';

class MessageService {
  final PocketBase pb = PocketBaseConfig.pb;

  // Obtener mensajes de un chat
  // En message_service.dart
  Future<List<MessageModel>> getChatMessages(String chatId) async {
  try {
    print('Obteniendo mensajes para el chat ID: $chatId'); // Depuración
    
    final result = await pb.collection(PocketBaseConfig.messagesCollection).getList(
      filter: 'idChat = "$chatId"',
      sort: 'created',
      expand: 'user1,user2',
    );
    
    print('Mensajes encontrados: ${result.items.length}'); // Depuración
    
    List<MessageModel> messages = [];
    for (var item in result.items) {
      try {
        final message = MessageModel.fromJson(item.toJson());
        messages.add(message);
      } catch (e) {
        print('Error al convertir mensaje: $e'); // Depuración
      }
    }
    
    return messages;
  } catch (e) {
    print('Error al obtener mensajes: $e'); // Depuración
    return [];
  }
}

// Mejorar el método para enviar mensajes de texto
Future<MessageModel> sendTextMessage(String chatId, String currentUserId, String otherUserId, String text) async {
  try {
    final now = DateTime.now();
    final fechaMensaje = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    
    final data = {
      'texto': text,
      'user1': currentUserId,
      'user2': otherUserId,
      'idChat': chatId,
      'fechaMensaje': fechaMensaje,
      'textoBool': true,
      'creado': true,
      'tipo': 'texto',
      'visto': false,
    };
    
    final record = await pb.collection(PocketBaseConfig.messagesCollection).create(body: data);
    
    // Actualizar último mensaje en el chat
    await pb.collection(PocketBaseConfig.chatsCollection).update(
      chatId, 
      body: {
        'ultimoMensaje': text,
        'fechaChat': "${now.day}/${now.month}/${now.year}",
        'horaChat': "${now.hour}:${now.minute}",
      },
    );
    
    return MessageModel.fromJson(record.toJson());
  } catch (e) {
    print('Error al enviar mensaje: $e');
    throw e;
  }
}

  // Enviar mensaje con archivo (imagen, audio, video, documento)
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required File file,
    required MessageType tipo,
    String? text,
  }) async {
    final now = DateTime.now();
    final fechaMensaje = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    
    final fileName = file.path.split('/').last;
    
    final formData = {
      'user1': currentUserId,
      'user2': otherUserId,
      'idChat': chatId,
      'fechaMensaje': fechaMensaje,
      'textoBool': text != null && text.isNotEmpty,
      'texto': text ?? '',
      'creado': true,
      'tipo': tipo.toString().split('.').last,
      'visto': false,
      'fileName': fileName,
    };
    
    // Dependiendo del tipo de archivo, lo agregamos al campo correspondiente
    if (tipo == MessageType.imagen) {
      formData['imagePath'] = file;
    } else if (tipo == MessageType.video) {
      formData['videoPath'] = file;
    } else if (tipo == MessageType.audio || tipo == MessageType.audioVoz) {
      formData['mp3'] = file;
    } else if (tipo == MessageType.documento) {
      formData['documentoPath'] = file;
    } else {
      formData['filePath'] = file;
    }
    
    final record = await pb.collection(PocketBaseConfig.messagesCollection).create(
      body: formData,
      files: [await http.MultipartFile.fromPath(fileName, file.path)],
    );
    
    return MessageModel.fromJson(record.toJson());
  }

  // Marcar mensaje como visto
  Future<void> markMessageAsRead(String messageId) async {
    await pb.collection(PocketBaseConfig.messagesCollection).update(
      messageId,
      body: {'visto': true},
    );
  }

  // Escuchar nuevos mensajes en tiempo real
  Future<UnsubscribeFunc> subscribeToMessages(String chatId) {
    return pb.collection(PocketBaseConfig.messagesCollection).subscribe('*', (e) {
      final message = MessageModel.fromJson(e.record!.toJson());
      if (message.idChat == chatId) {
        // Process the message here without returning it
        // For example, you can call a callback or update a state
      }
      throw Exception('No es un mensaje del chat actual');
    });
  }
}
