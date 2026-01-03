class Group {
  final String senderId;
  final String name;
  final String groupId;
  final String lastMessage;
  final String groupPic;
  final List<String> membersUid;
  final DateTime timeSent;
  Group({
    required this.senderId,
    required this.name,
    required this.groupId,
    required this.lastMessage,
    required this.groupPic,
    required this.membersUid,
    required this.timeSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'name': name,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'groupPic': groupPic,
      'membersUid': membersUid,
      'timeSent': timeSent.millisecondsSinceEpoch,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    // Обрабатываем timeSent - может быть ISO строка или int (миллисекунды)
    DateTime timeSent;
    if (map['timeSent'] == null) {
      timeSent = DateTime.now();
    } else if (map['timeSent'] is String) {
      // Если это ISO строка от бэкенда
      timeSent = DateTime.parse(map['timeSent'] as String);
    } else if (map['timeSent'] is int) {
      // Если это миллисекунды (для обратной совместимости)
      timeSent = DateTime.fromMillisecondsSinceEpoch(map['timeSent'] as int);
    } else {
      timeSent = DateTime.now();
    }

    return Group(
      senderId: map['senderId'] ?? '',
      name: map['name'] ?? '',
      groupId: map['groupId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      groupPic: map['groupPic'] ?? '',
      membersUid: map['membersUid'] != null ? List<String>.from(map['membersUid']) : [],
      timeSent: timeSent,
    );
  }
}
