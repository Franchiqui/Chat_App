// lib/providers/group_provider.dart
import 'package:flutter/foundation.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  List<GroupModel> _groups = [];
  List<Map<String, dynamic>> _groupMessages = [];
  bool _isLoading = false;
  String? _currentGroupId;

  List<GroupModel> get groups => _groups;
  List<Map<String, dynamic>> get groupMessages => _groupMessages;
  bool get isLoading => _isLoading;
  String? get currentGroupId => _currentGroupId;

  Future<void> getUserGroups(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(userId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GroupModel> createGroup(
      String currentUserId, String name, List<String> memberIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final group =
          await _groupService.createGroup(currentUserId, name, memberIds);
      _groups.add(group);
      notifyListeners();
      return group;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _groupService.addMemberToGroup(groupId, userId);
    getUserGroups(userId); // Actualizar la lista de grupos
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _groupService.removeMemberFromGroup(groupId, userId);
    getUserGroups(userId); // Actualizar la lista de grupos
  }

  Future<void> getGroupMessages(String groupId) async {
    _isLoading = true;
    _currentGroupId = groupId;
    notifyListeners();

    try {
      _groupMessages = await _groupService.getGroupMessages(groupId);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String currentUserId,
    required String text,
    dynamic file, // File o Uint8List
    MessageType tipo = MessageType.texto,
  }) async {
    await _groupService.sendGroupMessage(
      groupId: groupId,
      currentUserId: currentUserId,
      text: text,
      file: file,
      tipo: tipo,
    );

    // Recargar los mensajes después de enviar
    if (_currentGroupId == groupId) {
      getGroupMessages(groupId);
    }
  }

  void addGroupMessage(Map<String, dynamic> message) {
    if (message['grupo'] == _currentGroupId ||
        message['grupoId'] == _currentGroupId) {
      if (!_groupMessages.any((m) => m['id'] == message['id'])) {
        _groupMessages.add(message);
        notifyListeners();
      }
    }
  }

  GroupModel? getGroupById(String groupId) {
    // ignore: cast_from_null_always_fails
    return _groups.firstWhere((group) => group.id == groupId,
        orElse: () => null as GroupModel);
  }
}
