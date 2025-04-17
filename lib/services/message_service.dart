// lib/services/message_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
      final result =
          await pb.collection(PocketBaseConfig.messagesCollection).getList(
                filter: 'idChat = "$chatId"',
                sort: 'created',
                expand: 'user1,user2',
              );
      print('Mensajes RAW recibidos del backend:');
      for (var item in result.items) {
        print(item.toJson());
      }
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
      print('Mensajes filtrados y parseados:');
      for (var msg in messages) {
        print('id: ${msg.id}, texto: ${msg.texto}, idChat: ${msg.idChat}');
      }
      return messages;
    } catch (e) {
      print('Error al obtener mensajes: $e'); // Depuración
      return [];
    }
  }

// Mejorar el método para enviar mensajes de texto
  Future<MessageModel> sendTextMessage(String chatId, String currentUserId,
      String otherUserId, String text) async {
    try {
      final now = DateTime.now();
      final fechaMensaje =
          "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

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

      final record = await pb
          .collection(PocketBaseConfig.messagesCollection)
          .create(body: data);

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
  String safeFileName(String fileName) {
    // Solo letras, números, guion, guion bajo y punto
    return fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required dynamic file, // File (móvil) o Uint8List (web)
    required MessageType tipo,
    String? text,
    String? fileName, // solo para web
  }) async {
    final now = DateTime.now();
    final fechaMensaje =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    // Usa SIEMPRE el nombre real del archivo proporcionado por fileName
    if (fileName == null || fileName.isEmpty) {
      throw Exception('El nombre del archivo (fileName) es obligatorio y no puede ser vacío.');
    }
    final String nombreArchivo = safeFileName(fileName);

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
      'fileName': nombreArchivo,
    };

    // Determina el campo correcto para el archivo según el tipo
    String campoArchivo;
    if (tipo == MessageType.audio || tipo == MessageType.audioVoz) {
      campoArchivo = 'audio'; // Solo para audio
      // NO incluir en el body/formData
    } else {
      campoArchivo = 'filePath'; // Para imagen, video, documento, etc.
      // NO incluir en el body/formData
    }

    // NO pongas el archivo en el formData, solo en files
    // El archivo solo debe ir en la lista de archivos abajo
    // (El bloque de if (!kIsWeb) ... se elimina)

    print('--- DEBUG ENVÍO ARCHIVO ---');
    print('file.runtimeType: [36m${file.runtimeType}[0m');
    print('campoArchivo: [33m$campoArchivo[0m');
    print('nombreArchivo: [32m$nombreArchivo[0m');
    print('formData: $formData');
    print('----------------------------');

    List<http.MultipartFile> files = [];
    if (kIsWeb) {
      files.add(
        http.MultipartFile.fromBytes(
          campoArchivo,
          file as Uint8List,
          filename: nombreArchivo,
        ),
      );
    } else {
      files.add(
        await http.MultipartFile.fromPath(
          campoArchivo,
          (file as File).path,
          filename: nombreArchivo,
        ),
      );
    }

    final record =
        await pb.collection(PocketBaseConfig.messagesCollection).create(
              body: formData,
              files: files,
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
    return pb.collection(PocketBaseConfig.messagesCollection).subscribe('*',
        (e) {
      try {
        final message = MessageModel.fromJson(e.record!.toJson());
        print(
            '[subscribeToMessages] Recibido mensaje realtime id: [36m${message.id}[0m, idChat: ${message.idChat}');
        if (message.idChat == chatId) {
          // Aquí deberías llamar a un callback o actualizar estado
          print('[subscribeToMessages] Mensaje es del chat actual');
        } else {
          print(
              '[subscribeToMessages] Mensaje ignorado, no es del chat actual');
        }
      } catch (err) {
        print('[subscribeToMessages] Error parseando mensaje realtime: $err');
      }
    });
  }
}
