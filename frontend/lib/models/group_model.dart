class GroupModel {
  final String title;
  final String subtitle;
  final int memberCount;
  final bool hasUpdate;

  GroupModel({
    required this.title,
    required this.subtitle,
    required this.memberCount,
    this.hasUpdate = false,
  });
}
