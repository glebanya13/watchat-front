import 'package:watchat/common/enums/message_enum.dart';

class Message {
  final String senderId;
  final String recieverid;
  final String text;
  final MessageEnum type;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;
  final String repliedMessage;
  final String repliedTo;
  final MessageEnum repliedMessageType;

  Message({
    required this.senderId,
    required this.recieverid,
    required this.text,
    required this.type,
    required this.timeSent,
    required this.messageId,
    required this.isSeen,
    required this.repliedMessage,
    required this.repliedTo,
    required this.repliedMessageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recieverid': recieverid,
      'text': text,
      'type': type.type,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'messageId': messageId,
      'isSeen': isSeen,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType.type,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
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

    return Message(
      senderId: map['senderId'] ?? '',
      recieverid: map['recieverid'] ?? map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: (map['type'] as String? ?? 'text').toEnum(),
      timeSent: timeSent,
      messageId: map['messageId'] ?? '',
      isSeen: map['isSeen'] ?? false,
      repliedMessage: map['repliedMessage'] ?? '',
      repliedTo: map['repliedTo'] ?? '',
      repliedMessageType: (map['repliedMessageType'] as String? ?? 'text').toEnum(),
    );
  }
}
