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
    print('ENTRANDO A sendAudioBytesMessage');
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

    print('Antes de crear el mensaje');
    final record =
        await pb.collection(PocketBaseConfig.messagesCollection).create(
      body: formData,
      files: [
        await http.MultipartFile.fromPath('mp3', tempFile.path,
            filename: fileName)
      ],
    );
    print('Después de crear el mensaje, record.id: ${record.id}');

    // DEBUG: Mostrar el contenido del record y record.data
    print('PocketBase record creado: ' + record.toString());
    print('PocketBase record.data: ' + record.data.toString());

    // Esperar 1 segundo para que PocketBase procese el archivo y genere la URL
    await Future.delayed(const Duration(seconds: 1));

    // Usar siempre el campo 'audio' para obtener la URL pública
    // Construir manualmente la URL pública del archivo de audio
    final baseUrl = PocketBaseConfig.pb.baseUrl;
    final collectionName = record.collectionName ?? PocketBaseConfig.messagesCollection;
    final audioFileName = record.data['audio'];
    final manualAudioUrl = "$baseUrl/api/files/$collectionName/${record.id}/$audioFileName";

    print('Antes del update del mensaje con la URL');
    print('ID para el update: ' + record.id.toString());
    print('URL de audio generada manualmente: $manualAudioUrl');
    if (audioFileName != null && audioFileName.toString().isNotEmpty) {
      try {
        final updateResult = await pb.collection(PocketBaseConfig.messagesCollection).update(
          record.id,
          body: {
            'mp3_url': manualAudioUrl,
          },
        );
        print('[AUDIO][OK] mp3_url actualizado: $manualAudioUrl');
        print('Resultado de update PocketBase: ' + updateResult.toString());
        print('updateResult.data: ' + updateResult.data.toString());
      } catch (e, st) {
        print('ERROR al hacer update en PocketBase: ' + e.toString());
        print('STACKTRACE: ' + st.toString());
      }
    } else {
      print('[AUDIO][ERROR] No se pudo construir la URL del audio. Valor de audioFileName: $audioFileName');
    }

    // Devolver el mensaje actualizado
    final updatedRecord = await pb.collection(PocketBaseConfig.messagesCollection).getOne(record.id);
    print('Registro final actualizado: ' + updatedRecord.toString());
    print('updatedRecord.data: ' + updatedRecord.data.toString());
    return MessageModel.fromJson(updatedRecord.toJson());
  }
}
