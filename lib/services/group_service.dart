// lib/services/group_service.dart
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import 'dart:io';

class GroupService {
  final PocketBase pb = PocketBaseConfig.pb;

  // Obtener todos los grupos del usuario
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final result = await pb.collection(PocketBaseConfig.groupsCollection).getList(
      filter: 'members ~ "$userId"',
    );
    
    List<GroupModel> groups = [];
    for (var item in result.items) {
      groups.add(GroupModel.fromJson(item.toJson()));
    }
    
    return groups;
  }

  // Crear nuevo grupo
  Future<GroupModel> createGroup(String currentUserId, String name, List<String> memberIds) async {
    final now = DateTime.now();
    final fecha = "${now.day}/${now.month}/${now.year}";
    final hora = "${now.hour}:${now.minute}";
    
    final allMembers = [...memberIds, currentUserId];
    
    final data = {
      'nombreGrupo': name,
      'groupName': name,
      'user': currentUserId,
      'members': allMembers,
      'Miembros': allMembers,
      'miembrosId': allMembers.join(','),
      'fechaChat': fecha,
      'horaChat': hora,
      'visto': true,
    };
    
    final record = await pb.collection(PocketBaseConfig.groupsCollection).create(body: data);
    
    return GroupModel.fromJson(record.toJson());
  }

  // Añadir miembro al grupo
  Future<void> addMemberToGroup(String groupId, String userId) async {
    final group = await pb.collection(PocketBaseConfig.groupsCollection).getOne(groupId);
    
    List<String> members = List<String>.from(group.data['members'] ?? []);
    List<dynamic> miembros = List<dynamic>.from(group.data['Miembros'] ?? []);
    
    if (!members.contains(userId)) {
      members.add(userId);
      miembros.add(userId);
      
      await pb.collection(PocketBaseConfig.groupsCollection).update(
        groupId,
        body: {
          'members': members,
          'Miembros': miembros,
          'miembrosId': members.join(','),
        },
      );
    }
  }

  // Eliminar miembro del grupo
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final group = await pb.collection(PocketBaseConfig.groupsCollection).getOne(groupId);
    
    List<String> members = List<String>.from(group.data['members'] ?? []);
    List<dynamic> miembros = List<dynamic>.from(group.data['Miembros'] ?? []);
    
    members.remove(userId);
    miembros.remove(userId);
    
    await pb.collection(PocketBaseConfig.groupsCollection).update(
      groupId,
      body: {
        'members': members,
        'Miembros': miembros,
        'miembrosId': members.join(','),
      },
    );
  }

  // Enviar mensaje al grupo
  Future<void> sendGroupMessage({
    required String groupId,
    required String currentUserId,
    required String text,
    File? file,
    MessageType tipo = MessageType.texto,
  }) async {
    final group = await pb.collection(PocketBaseConfig.groupsCollection).getOne(groupId);
    
    final data = {
      'texto': text,
      'user': currentUserId,
      'grupo': groupId,
      'groupId': groupId,
      'grupoId': groupId,
      'groupName': group.data['nombreGrupo'],
      'grupoName': group.data['nombreGrupo'],
      'Miembros': group.data['Miembros'],
      'tipo': tipo.toString().split('.').last,
    };
    
    if (file != null) {
      data['filePath'] = null; // Se añadirá en el archivo
    }
    
    final formData = {...data};
    
    if (file != null) {
      await pb.collection(PocketBaseConfig.groupMessagesCollection).create(
        body: formData,
        files: [await MultipartFile.fromPath('file', file.path, filename: file.uri.pathSegments.last)],
      );
    } else {
      await pb.collection(PocketBaseConfig.groupMessagesCollection).create(body: formData);
    }
    
    // Actualizar último mensaje del grupo
    await pb.collection(PocketBaseConfig.groupsCollection).update(
      groupId,
      body: {
        'ultimoMensaje': text,
        'fechaChat': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
        'horaChat': "${DateTime.now().hour}:${DateTime.now().minute}",
      },
    );
  }

  // Obtener mensajes del grupo
  Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    final result = await pb.collection(PocketBaseConfig.groupMessagesCollection).getList(
      filter: 'grupo = "$groupId"',
      sort: 'created',
      expand: 'user',
    );
    
    List<Map<String, dynamic>> messages = [];
    for (var item in result.items) {
      final data = item.toJson();
      final user = data['expand']?['user'];
      
      messages.add({
        ...data,
        'senderName': user?['displayName_A'] ?? 'Usuario',
        'senderAvatar': user?['avatar'],
      });
    }
    
    return messages;
  }

  // Escuchar mensajes del grupo en tiempo real
  Future<UnsubscribeFunc> subscribeToGroupMessages(String groupId) {
    return pb.collection(PocketBaseConfig.groupMessagesCollection).subscribe('*', (e) {
      final data = e.record!.toJson();
      if (data['grupo'] == groupId || data['grupoId'] == groupId) {
        // Handle the data here without returning it
        print('New message received: $data');
      } else {
        throw Exception('No es un mensaje del grupo actual');
      }
    });
  }
}
