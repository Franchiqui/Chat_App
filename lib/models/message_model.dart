// lib/models/message_model.dart
enum MessageType { texto, audioVoz, audio, imagen, video, documento }

class MessageModel {
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
