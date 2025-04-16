import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/group_invitation_model.dart';
import '../services/group_service.dart';

class GroupInvitationService {
  final PocketBase pb = PocketBaseConfig.pb;
  final String collection = 'group_invitations';

  // Crear una invitación
  Future<GroupInvitationModel?> createInvitation({
    required String groupId,
    required String fromUserId,
    required String toUserId,
  }) async {
    final data = {
      'groupId': groupId,
      'fromUser': fromUserId,
      'toUser': toUserId,
      'status': 'pending',
    };
    final record = await pb.collection(collection).create(body: data);
    return GroupInvitationModel.fromJson(record.toJson());
  }

  // Listar invitaciones por usuario
  Future<List<GroupInvitationModel>> getInvitationsForUser(
      String userId) async {
    final result = await pb.collection(collection).getList(
          filter: 'toUser = "$userId"',
          sort: '-created',
        );
    return result.items
        .map((item) => GroupInvitationModel.fromJson(item.toJson()))
        .toList();
  }

  // Aceptar invitación
  Future<bool> acceptInvitation(String invitationId) async {
    // 1. Obtener la invitación
    final invitationRecord =
        await pb.collection(collection).getOne(invitationId);
    final invitation = GroupInvitationModel.fromJson(invitationRecord.toJson());

    // 2. Actualizar el estado a 'accepted'
    await pb
        .collection(collection)
        .update(invitationId, body: {'status': 'accepted'});

    // 3. Añadir el usuario invitado al grupo
    try {
      // Importa GroupService
      // ignore: unused_import

      final groupService = GroupService();
      await groupService.addMemberToGroup(
          invitation.groupId, invitation.toUserId);
      return true;
    } catch (e) {
      print('[GroupInvitationService] Error al añadir miembro al grupo: $e');
      return false;
    }
  }

  // Rechazar invitación
  Future<bool> rejectInvitation(String invitationId) async {
    final updated = await pb
        .collection(collection)
        .update(invitationId, body: {'status': 'rejected'});
    return updated != null;
  }
}
