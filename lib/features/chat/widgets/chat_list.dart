import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watchat/common/enums/message_enum.dart';
import 'package:watchat/common/providers/message_reply_provider.dart';
import 'package:watchat/common/widgets/loader.dart';
import 'package:watchat/common/api/api_service.dart';

import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/features/chat/controller/chat_controller.dart';
import 'package:watchat/features/chat/widgets/my_message_card.dart';
import 'package:watchat/features/chat/widgets/sender_message_card.dart';
import 'package:watchat/models/message.dart';
import 'package:watchat/models/user_model.dart';

class ChatList extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;
  const ChatList({
    Key? key,
    required this.recieverUserId,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();

  Future<UserModel?> _getUserById(String uid) async {
    try {
      return await ApiService.getUserById(uid);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
    ref.read(messageReplyProvider.state).update(
          (state) => MessageReply(
            message,
            isMe,
            messageEnum,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
        stream: widget.isGroupChat
            ? ref
                .read(chatControllerProvider)
                .groupChatStream(widget.recieverUserId)
            : ref
                .read(chatControllerProvider)
                .chatStream(widget.recieverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          SchedulerBinding.instance.addPostFrameCallback((_) {
            messageController
                .jumpTo(messageController.position.maxScrollExtent);
          });

          return ListView.builder(
            controller: messageController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final messageData = snapshot.data![index];
              var timeSent = DateFormat.Hm().format(messageData.timeSent);

              // Получаем текущего пользователя
              final currentUserAsync = ref.watch(userDataAuthProvider);
              final currentUser = currentUserAsync.value;
              String? currentUserUid = currentUser?.uid;
              
              if (currentUserUid != null &&
                  !messageData.isSeen &&
                  messageData.recieverid == currentUserUid) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                      context,
                      widget.recieverUserId,
                      messageData.messageId,
                    );
              }
              if (currentUserUid != null &&
                  messageData.senderId == currentUserUid) {
                return MyMessageCard(
                  message: messageData.text,
                  date: timeSent,
                  type: messageData.type,
                  repliedText: messageData.repliedMessage,
                  username: messageData.repliedTo,
                  repliedMessageType: messageData.repliedMessageType,
                  onLeftSwipe: () => onMessageSwipe(
                    messageData.text,
                    true,
                    messageData.type,
                  ),
                  isSeen: messageData.isSeen,
                );
              }
              
              if (widget.isGroupChat) {
                // Для групповых чатов получаем имя отправителя из API
                return FutureBuilder<UserModel?>(
                  future: _getUserById(messageData.senderId),
                  builder: (context, userSnapshot) {
                    String senderName = messageData.senderId;
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      senderName = userSnapshot.data!.name;
                    }
                    
                    return SenderMessageCard(
                      message: messageData.text,
                      date: timeSent,
                      type: messageData.type,
                      username: messageData.repliedTo,
                      repliedMessageType: messageData.repliedMessageType,
                      onRightSwipe: () => onMessageSwipe(
                        messageData.text,
                        false,
                        messageData.type,
                      ),
                      repliedText: messageData.repliedMessage,
                      senderName: senderName,
                      isGroupChat: true,
                    );
                  },
                );
              }
              
              return SenderMessageCard(
                message: messageData.text,
                date: timeSent,
                type: messageData.type,
                username: messageData.repliedTo,
                repliedMessageType: messageData.repliedMessageType,
                onRightSwipe: () => onMessageSwipe(
                  messageData.text,
                  false,
                  messageData.type,
                ),
                repliedText: messageData.repliedMessage,
                isGroupChat: false,
              );
            },
          );
        });
  }
}
