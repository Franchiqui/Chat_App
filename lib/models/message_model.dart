// lib/models/message_model.dart
import '../config/pocketbase_config.dart';

enum MessageType { texto, audioVoz, audio, imagen, video, documento }

class MessageModel {
  // Devuelve la URL del video si existe, si no la construye a partir de filePath
  String? get videoUrl {
    if (mensajeUrl != null && mensajeUrl!.isNotEmpty) return mensajeUrl;
    if (filePath != null && (tipo == MessageType.video || tipo == MessageType.imagen || tipo == MessageType.audio || tipo == MessageType.audioVoz || tipo == MessageType.documento)) {
      final baseUrl = PocketBaseConfig.pb.baseUrl;
      return '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/$id/$filePath';
    }
    return null;
  }

  // Devuelve la URL del documento si existe, si no la construye a partir de filePath
  String? get documentUrl {
    if (mensajeUrl != null && mensajeUrl!.isNotEmpty) return mensajeUrl;
    if (filePath != null && (tipo == MessageType.documento || tipo == MessageType.imagen || tipo == MessageType.video || tipo == MessageType.audio || tipo == MessageType.audioVoz)) {
      final baseUrl = PocketBaseConfig.pb.baseUrl;
      return '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/$id/$filePath';
    }
    return null;
  }

  // Devuelve la URL de la imagen si existe, si no la construye a partir de filePath
  String? get imageUrl {
    if (imagenUrl != null && imagenUrl!.isNotEmpty) return imagenUrl;
    if (filePath != null && (tipo == MessageType.imagen || tipo == MessageType.video || tipo == MessageType.documento || tipo == MessageType.audio || tipo == MessageType.audioVoz)) {
      final baseUrl = PocketBaseConfig.pb.baseUrl;
      return '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/$id/$filePath';
    }
    return null;
  }

  // Devuelve la URL del audio si existe, si no la construye a partir de filePath
  String? get audioUrl {
    if (mp3Url != null && mp3Url!.isNotEmpty) return mp3Url;
    if (filePath != null && (tipo == MessageType.audio || tipo == MessageType.audioVoz || tipo == MessageType.imagen || tipo == MessageType.video || tipo == MessageType.documento)) {
      final baseUrl = PocketBaseConfig.pb.baseUrl;
      return '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/$id/$filePath';
    }
    return null;
  }

  final String id;
  final String texto;
  final String user1;
  final String user2;
  final String idChat;
  final String? senderAvatar;
  final String fechaMensaje;
  final bool textoBool;
  final bool creado;
  final String? displayNameB;
  final String? userId;
  final MessageType tipo;
  final bool visto;
  final String? filePath;
  final String? fileName;
  final String? mensajeUrl;
  final String? imagenUrl;
  final String? mp3Url;
  final String? status;

  MessageModel({
    required this.id,
    required this.texto,
    required this.user1,
    required this.user2,
    required this.idChat,
    required this.senderAvatar,
    required this.fechaMensaje,
    required this.textoBool,
    required this.creado,
    this.displayNameB,
    this.userId,
    required this.tipo,
    required this.visto,
    this.filePath,
    this.fileName,
    this.mensajeUrl,
    this.imagenUrl,
    this.mp3Url,
    this.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Depuración
    print('Datos del mensaje: ${json.toString()}');
    // Lógica robusta para obtener el avatar correcto del remitente
    String? senderAvatar;
    final userId = json['user'] is Map
        ? json['user']['id'].toString()
        : json['user']?.toString();
    if (json['expand'] != null) {
      final user1 = json['expand']['user1'];
      final user2 = json['expand']['user2'];
      if (user1 != null && user1['id']?.toString() == userId) {
        senderAvatar = user1['avatar'];
      } else if (user2 != null && user2['id']?.toString() == userId) {
        senderAvatar = user2['avatar'];
      }
    }
    // Determinar el tipo de mensaje
    final String tipoStr = json['tipo'] ?? 'texto';
    MessageType tipo = _parseMessageType(tipoStr);

    return MessageModel(
      id: json['id']?.toString() ?? '',
      texto: json['texto']?.toString() ?? '',
      user1: json['user1']?.toString() ?? '',
      user2: json['user2']?.toString() ?? '',
      idChat: json['idChat']?.toString() ?? '',
      senderAvatar: senderAvatar?.toString() ?? '',
      fechaMensaje: json['fechaMensaje']?.toString() ?? '',
      textoBool: json['textoBool'] ?? false,
      creado: json['creado'] ?? false,
      displayNameB: json['displayName_B']?.toString(),
      userId: json['user'] is Map
          ? json['user']['id'].toString()
          : json['user']?.toString(),
      tipo: tipo,
      visto: json['visto'] ?? false,
      filePath: json['filePath'],
      fileName: json['fileName'],
      mensajeUrl: json['mensajeUrl'],
      imagenUrl: json['imagenUrl'],
      mp3Url: json['mp3_url'],
      status: json['status'],
    );
  }

  get senderId => null;

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'audioVoz':
        return MessageType.audioVoz;
      case 'audio':
        return MessageType.audio;
      case 'imagen':
        return MessageType.imagen;
      case 'video':
        return MessageType.video;
      case 'documento':
        return MessageType.documento;
      case 'texto':
      default:
        return MessageType.texto;
    }
  }
}
