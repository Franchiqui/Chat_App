import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';

class MessageService {
  final PocketBase pb = PocketBaseConfig.pb;

  // ... [otras funciones existentes] ...

  /// Envía un mensaje de audio grabado desde bytes (web y móvil).
  Future<MessageModel> sendAudioBytesMessage({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required Uint8List audioBytes,
    required String fileName,
    String? text,
  }) async {
    final now = DateTime.now();
    final fechaMensaje =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    // Guardar temporalmente el archivo en disco (móvil) o usar bytes directamente (web)
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      tempFile = File(filePath);
      await tempFile.writeAsBytes(audioBytes);
    } catch (e) {
      print('Error creando archivo temporal para audio: $e');
      rethrow;
    }

    final formData = {
      'user1': currentUserId,
      'user2': otherUserId,
      'idChat': chatId,
      'fechaMensaje': fechaMensaje,
      'textoBool': text != null && text.isNotEmpty,
      'texto': text ?? '',
      'creado': true,
      'tipo': MessageType.audioVoz.toString().split('.').last,
      'visto': false,
      'fileName': fileName,
    };
    formData['mp3'] = tempFile;

    final record =
        await pb.collection(PocketBaseConfig.messagesCollection).create(
      body: formData,
      files: [
        await http.MultipartFile.fromPath('mp3', tempFile.path,
            filename: fileName)
      ],
    );
    return MessageModel.fromJson(record.toJson());
  }
}
