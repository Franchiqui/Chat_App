// lib/models/message_model.dart
enum MessageType { texto, audioVoz, audio, imagen, video, documento }

class MessageModel {
  final String id;
  final String texto;
  final String user1;
  final String user2;
  final String idChat;
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
    return MessageModel(
      id: json['id'],
      texto: json['texto'] ?? '',
      user1: json['user1'] ?? '',
      user2: json['user2'] ?? '',
      idChat: json['idChat'] ?? '',
      fechaMensaje: json['fechaMensaje'] ?? '',
      textoBool: json['textoBool'] ?? false,
      creado: json['creado'] ?? false,
      displayNameB: json['displayName_B'],
      userId: json['user']?['id'],
      tipo: _parseMessageType(json['tipo']),
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
