class GroupInvitationModel {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime created;

  GroupInvitationModel({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.created,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      fromUserId: json['fromUser']?.toString() ?? '',
      toUserId: json['toUser']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      created: DateTime.tryParse(json['created']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'fromUser': fromUserId,
    'toUser': toUserId,
    'status': status,
    'created': created.toIso8601String(),
  };
}
