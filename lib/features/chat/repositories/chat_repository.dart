import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_client.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/enums/message_enum.dart';
import 'package:watchat/common/providers/message_reply_provider.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/models/chat_contact.dart';
import 'package:watchat/models/group.dart';
import 'package:watchat/models/message.dart';
import 'package:watchat/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(ref: ref),
);

class ChatRepository {
  final ProviderRef ref;
  
  ChatRepository({
    required this.ref,
  });

  String? getCurrentUserPhoneKey() {
    return null;
  }

  Stream<List<ChatContact>> getChatContacts() {
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      try {
        final token = await ApiClient.getToken();
        if (token == null) {
          return <ChatContact>[];
        }
        final contactsData = await ApiService.getChatContacts();
        return contactsData.map((data) => ChatContact.fromMap(data)).toList();
      } catch (e) {
        return <ChatContact>[];
      }
    }).asyncMap((future) => future);
  }

  Stream<List<Group>> getChatGroups() {
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      try {
        final token = await ApiClient.getToken();
        if (token == null) {
          return <Group>[];
        }
        return await ApiService.getUserGroups();
      } catch (e) {
        return <Group>[];
      }
    }).asyncMap((future) => future);
  }

  Stream<List<Message>> getChatStream(String recieverUserId) {
    if (recieverUserId.isEmpty) {
      return Stream.value([]);
    }
    return Stream.periodic(const Duration(seconds: 2), (_) async {
      try {
        final token = await ApiClient.getToken();
        if (token == null) {
          return <Message>[];
        }
        return await ApiService.getChatMessages(recieverUserId);
      } catch (e) {
        return <Message>[];
      }
    }).asyncMap((future) => future);
  }

  Stream<List<Message>> getGroupChatStream(String groupId) {
    if (groupId.isEmpty) {
      return Stream.value([]);
    }
    return Stream.periodic(const Duration(seconds: 2), (_) async {
      try {
        final token = await ApiClient.getToken();
        if (token == null) {
          return <Message>[];
        }
        return await ApiService.getGroupMessages(groupId);
      } catch (e) {
        return <Message>[];
      }
    }).asyncMap((future) => future);
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        showSnackBar(context: context, content: 'Пользователь не авторизован');
        return;
      }

      await ApiService.sendMessage(
        receiverId: isGroupChat ? null : recieverUserId,
        groupId: isGroupChat ? recieverUserId : null,
        text: text,
        type: MessageEnum.text,
        repliedMessage: messageReply?.message ?? '',
        repliedTo: messageReply == null
            ? ''
            : messageReply.isMe
                ? senderUser.name
                : '',
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('заблокирован') || errorMessage.contains('Blocked') || errorMessage.contains('Forbidden')) {
        showSnackBar(context: context, content: 'Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.');
      } else {
        String cleanMessage = errorMessage.replaceAll('Exception: ', '').replaceAll('Exception:', '');
        showSnackBar(context: context, content: cleanMessage);
      }
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required dynamic file, 
    required String recieverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageEnum,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      String folder = 'chat';
      String fileName = 'file';
      List<int> fileBytes;

      if (file is File) {
        fileName = file.path.split('/').last;
        if (fileName.isEmpty) {
          fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';
        }
        fileBytes = await file.readAsBytes();
      } else if (kIsWeb && file is XFile) {
        fileName = file.name.isNotEmpty ? file.name : 'file_${DateTime.now().millisecondsSinceEpoch}';
        fileBytes = await file.readAsBytes();
      } else if (kIsWeb && file is PlatformFile) {
        if (file.bytes == null) {
          showSnackBar(context: context, content: 'Не удалось прочитать файл');
          return;
        }
        fileName = file.name.isNotEmpty ? file.name : 'file_${DateTime.now().millisecondsSinceEpoch}';
        fileBytes = file.bytes!;
      } else {
        showSnackBar(context: context, content: 'Неподдерживаемый тип файла');
        return;
      }
      
      if (fileName.isEmpty) {
        fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';
      }

      folder = 'chat/files';

      String fileUrl = await ApiService.uploadFile(fileBytes, folder, fileName);

      await ApiService.sendMessage(
        receiverId: isGroupChat ? null : recieverUserId,
        groupId: isGroupChat ? recieverUserId : null,
        text: fileUrl,
        type: MessageEnum.file,
        repliedMessage: messageReply?.message ?? '',
        repliedTo: messageReply == null
            ? ''
            : messageReply.isMe
                ? senderUserData.name
                : '',
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('заблокирован') || errorMessage.contains('Blocked') || errorMessage.contains('Forbidden')) {
        showSnackBar(context: context, content: 'Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.');
      } else {
        String cleanMessage = errorMessage.replaceAll('Exception: ', '').replaceAll('Exception:', '');
        showSnackBar(context: context, content: 'Ошибка отправки файла: $cleanMessage');
      }
    }
  }

  void sendGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      await ApiService.sendMessage(
        receiverId: isGroupChat ? null : recieverUserId,
        groupId: isGroupChat ? recieverUserId : null,
        text: gifUrl,
        type: MessageEnum.gif,
        repliedMessage: messageReply?.message ?? '',
        repliedTo: messageReply == null
            ? ''
            : messageReply.isMe
                ? senderUser.name
                : '',
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('заблокирован') || errorMessage.contains('Blocked') || errorMessage.contains('Forbidden')) {
        showSnackBar(context: context, content: 'Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.');
      } else {
        String cleanMessage = errorMessage.replaceAll('Exception: ', '').replaceAll('Exception:', '');
        showSnackBar(context: context, content: cleanMessage);
      }
    }
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) async {
    try {
      await ApiService.markMessageAsSeen(messageId);
    } catch (e) {
      String errorMessage = e.toString();
      // Проверяем, является ли ошибка блокировкой пользователя
      if (errorMessage.contains('заблокирован') || errorMessage.contains('Blocked')) {
        showSnackBar(context: context, content: 'Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.');
      } else {
        showSnackBar(context: context, content: errorMessage);
      }
    }
  }
}
