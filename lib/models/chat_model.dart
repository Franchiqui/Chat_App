// lib/models/chat_model.dart
class ChatModel {
  final String id;
  final String user1;
  final String user2;
  final String displayNameA;
  final String displayNameB;
  final String? fotoUrlA;
  final String? fotoUrlB;
  final String? fechaChat;
  final String? horaChat;
  final String? ultimoMensaje;
  final String? visto;

  ChatModel({
    required this.id,
    required this.user1,
    required this.user2,
    required this.displayNameA,
    required this.displayNameB,
    this.fotoUrlA,
    this.fotoUrlB,
    this.fechaChat,
    this.horaChat,
    this.ultimoMensaje,
    this.visto,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      user1: json['user1'],
      user2: json['user2'],
      displayNameA: json['displayName_A'],
      displayNameB: json['displayName_B'],
      fotoUrlA: json['fotoUrl_A'],
      fotoUrlB: json['fotoUrl_B'],
      fechaChat: json['fechaChat'],
      horaChat: json['horaChat'],
      ultimoMensaje: json['ultimoMensaje'],
      visto: json['visto'],
    );
  }
}
