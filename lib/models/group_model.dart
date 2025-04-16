// lib/models/group_model.dart
class GroupModel {
  final String id;
  final List<dynamic> miembros;
  final String? userId;
  final String nombreGrupo;
  final String? groupName;
  final String? fechaChat;
  final String? horaChat;
  final String? ultimoMensaje;
  final bool visto;
  final List<String>? membersIds;
  final String? miembrosId;

  GroupModel({
    required this.id,
    required this.miembros,
    this.userId,
    required this.nombreGrupo,
    this.groupName,
    this.fechaChat,
    this.horaChat,
    this.ultimoMensaje,
    required this.visto,
    this.membersIds,
    this.miembrosId,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    // Manejo robusto del userId, puede venir como String o como Map
    String? userId;
    if (json['user'] is String) {
      userId = json['user'];
    } else if (json['user'] is Map && json['user']['id'] != null) {
      userId = json['user']['id'].toString();
    }
    return GroupModel(
      id: json['id'] as String,
      miembros: json['Miembros'] ?? [],
      userId: userId,
      nombreGrupo: json['nombreGrupo'] as String,
      groupName: json['groupName'] as String?,
      fechaChat: json['fechaChat'] as String?,
      horaChat: json['horaChat'] as String?,
      ultimoMensaje: json['ultimoMensaje'] as String?,
      visto: json['visto'] ?? false,
      membersIds: json['members'] != null ? List<String>.from(json['members']) : null,
      miembrosId: json['miembrosId'] as String?,
    );
  }
}
