// /lib/features/mapa_tatico/models/group_invite.dart

class GroupInvite {
  final int id;
  final int groupId;
  final String email;
  final int invitedById;
  final String status;
  final DateTime createdAt;
  final String? groupName;

  GroupInvite({
    required this.id,
    required this.groupId,
    required this.email,
    required this.invitedById,
    required this.status,
    required this.createdAt,
    this.groupName,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      email: json['email'] as String,
      invitedById: json['invited_by_id'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      groupName: json['group_name'] as String?,
    );
  }

  bool get isPending => status == 'PENDING';
}
