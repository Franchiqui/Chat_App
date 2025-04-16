import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../config/pocketbase_config.dart';

class FileUploadService {
  final PocketBase pb = PocketBaseConfig.pb;

  /// Sube un archivo a la colección de archivos de PocketBase y devuelve la URL pública.
  Future<Uri?> uploadFile(File file, {String collection = 'archivos'}) async {
    try {
      final multipartFile =
          await http.MultipartFile.fromPath('file', file.path);
      final record = await pb.collection(collection).create(
        body: {},
        files: [multipartFile],
      );
      // Obtén la URL pública del archivo subido
      final fileUrl = pb.files.getURL(record, record.data['file']);
      return fileUrl;
    } catch (e) {
      print('Error al subir archivo: $e');
      return null;
    }
  }
}
