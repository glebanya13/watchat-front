class ChatContact {
  final String name;
  final String profilePic;
  final String contactId;
  final DateTime timeSent;
  final String lastMessage;
  ChatContact({
    required this.name,
    required this.profilePic,
    required this.contactId,
    required this.timeSent,
    required this.lastMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePic': profilePic,
      'contactId': contactId,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
    };
  }

  factory ChatContact.fromMap(Map<String, dynamic> map) {
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

    return ChatContact(
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      contactId: map['contactId'] ?? '',
      timeSent: timeSent,
      lastMessage: map['lastMessage'] ?? '',
    );
  }
}
