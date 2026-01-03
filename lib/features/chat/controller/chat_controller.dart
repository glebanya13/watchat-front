import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/enums/message_enum.dart';
import 'package:watchat/common/providers/message_reply_provider.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/features/chat/repositories/chat_repository.dart';
import 'package:watchat/models/chat_contact.dart';
import 'package:watchat/models/group.dart';
import 'package:watchat/models/message.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;
  ChatController({
    required this.chatRepository,
    required this.ref,
  });

  Stream<List<ChatContact>> chatContacts() {
    return chatRepository.getChatContacts();
  }

  Stream<List<Group>> chatGroups() {
    return chatRepository.getChatGroups();
  }

  Stream<List<Message>> chatStream(String recieverUserId) {
    return chatRepository.getChatStream(recieverUserId);
  }

  Stream<List<Message>> groupChatStream(String groupId) {
    return chatRepository.getGroupChatStream(groupId);
  }

  void sendTextMessage(
    BuildContext context,
    String text,
    String recieverUserId,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData(
          (value) {
            if (value != null) {
              chatRepository.sendTextMessage(
                context: context,
                text: text,
                recieverUserId: recieverUserId,
                senderUser: value,
                messageReply: messageReply,
                isGroupChat: isGroupChat,
              );
            } else {
              showSnackBar(context: context, content: 'Пользователь не авторизован');
            }
          },
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void sendFileMessage(
    BuildContext context,
    dynamic file, 
    String recieverUserId,
    MessageEnum messageEnum,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData(
          (value) {
            if (value != null) {
              chatRepository.sendFileMessage(
                context: context,
                file: file,
                recieverUserId: recieverUserId,
                senderUserData: value,
                messageEnum: messageEnum,
                ref: ref,
                messageReply: messageReply,
                isGroupChat: isGroupChat,
              );
            } else {
              showSnackBar(context: context, content: 'Пользователь не авторизован');
            }
          },
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void sendGIFMessage(
    BuildContext context,
    String gifUrl,
    String recieverUserId,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String newgifUrl = 'https://i.giphy.com/media/${gifUrl.substring(gifUrlPartIndex)}/200.gif';

    ref.read(userDataAuthProvider).whenData(
          (value) {
            if (value != null) {
              chatRepository.sendGIFMessage(
                context: context,
                gifUrl: newgifUrl,
                recieverUserId: recieverUserId,
                senderUser: value,
                messageReply: messageReply,
                isGroupChat: isGroupChat,
              );
            } else {
              showSnackBar(context: context, content: 'Пользователь не авторизован');
            }
          },
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) {
    chatRepository.setChatMessageSeen(
      context,
      recieverUserId,
      messageId,
    );
  }
}
