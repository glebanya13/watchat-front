import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/utils/colors.dart';
import 'package:watchat/common/enums/message_enum.dart';
import 'package:watchat/common/providers/message_reply_provider.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/features/chat/controller/chat_controller.dart';
import 'package:watchat/features/chat/widgets/message_reply_preview.dart';

class BottomChatField extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;
  const BottomChatField({
    Key? key,
    required this.recieverUserId,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _SelectedFile {
  final dynamic file;
  final MessageEnum type;
  
  _SelectedFile(this.file, this.type);
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> {
  bool isShowSendButton = false;
  final TextEditingController _messageController = TextEditingController();
  bool isShowEmojiContainer = false;
  FocusNode focusNode = FocusNode();
  List<_SelectedFile> _selectedFiles = [];

  void sendTextMessage() {
    String message = _messageController.text.trim();
    
    if (_selectedFiles.isNotEmpty) {
      _sendSelectedFiles();
      if (message.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          ref.read(chatControllerProvider).sendTextMessage(
                context,
                message,
                widget.recieverUserId,
                widget.isGroupChat,
              );
        });
        setState(() {
          _messageController.text = '';
        });
      }
      return;
    }
    
    if (message.isNotEmpty) {
      ref.read(chatControllerProvider).sendTextMessage(
            context,
            message,
            widget.recieverUserId,
            widget.isGroupChat,
          );
      setState(() {
        _messageController.text = '';
        isShowSendButton = false;
      });
    }
  }

  void sendFileMessage(
    dynamic file,
    MessageEnum messageEnum,
  ) {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          file,
          widget.recieverUserId,
          messageEnum,
          widget.isGroupChat,
        );
  }

  void selectFile() async {
    // Позволяем выбрать как файлы, так и изображения
    dynamic file = await pickFileFromDevice(context);
    if (file != null) {
      setState(() {
        // Все файлы (включая фото) отправляем как MessageEnum.file
        _selectedFiles.add(_SelectedFile(file, MessageEnum.file));
        isShowSendButton = true;
      });
    }
  }
  
  void selectImageAsFile() async {
    // Выбираем изображение, но отправляем как файл
    dynamic image = await pickImageFromGallery(context);
    if (image != null) {
      setState(() {
        _selectedFiles.add(_SelectedFile(image, MessageEnum.file));
        isShowSendButton = true;
      });
    }
  }

  void _clearSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_selectedFiles.isEmpty && _messageController.text.trim().isEmpty) {
        isShowSendButton = false;
      }
    });
  }

  void _clearAllSelectedFiles() {
    setState(() {
      _selectedFiles.clear();
      if (_messageController.text.trim().isEmpty) {
        isShowSendButton = false;
      }
    });
  }

  void _sendSelectedFiles() {
    if (_selectedFiles.isEmpty) return;
    
    final filesToSend = List<_SelectedFile>.from(_selectedFiles);
    _clearAllSelectedFiles();
    
    for (int i = 0; i < filesToSend.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        sendFileMessage(filesToSend[i].file, filesToSend[i].type);
      });
    }
  }

  void selectGIF() async {
    final gif = await pickGIF(context);
    if (gif != null) {
      ref.read(chatControllerProvider).sendGIFMessage(
            context,
            gif.url,
            widget.recieverUserId,
            widget.isGroupChat,
          );
    }
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void showKeyboard() => focusNode.requestFocus();
  void hideKeyboard() => focusNode.unfocus();

  String _getFileName(dynamic file) {
    if (file == null) return 'Файл';
    try {
      String fullName;
      if (kIsWeb) {
        if (file is PlatformFile) {
          fullName = file.name;
        } else {
          fullName = (file as dynamic).name ?? 'Файл';
        }
      } else {
        fullName = (file as File).path.split('/').last;
      }
      
      int lastDot = fullName.lastIndexOf('.');
      String name = lastDot > 0 ? fullName.substring(0, lastDot) : fullName;
      String extension = lastDot > 0 ? fullName.substring(lastDot) : '';
      
      if (name.length <= 5) {
        return fullName;
      } else {
        return '${name.substring(0, 5)}...$extension';
      }
    } catch (e) {
      return 'Файл';
    }
  }
  
  IconData _getFileIcon(MessageEnum type) {
    // Все файлы теперь отправляются как MessageEnum.file
    return Icons.insert_drive_file;
  }

  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageReply = ref.watch(messageReplyProvider);
    final isShowMessageReply = messageReply != null;
    return Column(
      children: [
        isShowMessageReply ? const MessageReplyPreview() : const SizedBox(),
        if (_selectedFiles.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            height: 56,
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final selectedFile = entry.value;
                  return Container(
                    width: 150,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: mobileChatBoxColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(selectedFile.type),
                          color: tabColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getFileName(selectedFile.file),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _clearSelectedFile(index),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                focusNode: focusNode,
                controller: _messageController,
                onChanged: (val) {
                  setState(() {
                    isShowSendButton = val.trim().isNotEmpty || _selectedFiles.isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: mobileChatBoxColor,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: toggleEmojiKeyboardContainer,
                            icon: const Icon(
                              Icons.emoji_emotions,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            onPressed: selectGIF,
                            icon: const Icon(
                              Icons.gif,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  suffixIcon: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: selectFile,
                          icon: const Icon(
                            Icons.attach_file,
                            color: Colors.grey,
                          ),
                          tooltip: 'Прикрепить файл',
                        ),
                        IconButton(
                          onPressed: selectImageAsFile,
                          icon: const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                          tooltip: 'Прикрепить фото',
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Введите сообщение',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 4,
                right: 2,
                left: 2,
              ),
              child: CircleAvatar(
                backgroundColor: isShowSendButton 
                    ? const Color(0xFF128C7E)
                    : Colors.grey[700]!,
                radius: 25,
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: isShowSendButton 
                        ? Colors.white
                        : Colors.grey[400]!,
                  ),
                  onPressed: isShowSendButton ? sendTextMessage : null,
                ),
              ),
            ),
          ],
        ),
        isShowEmojiContainer
            ? Container(
                height: 310,
                child: Stack(
                  children: [
                    EmojiPicker(
                      onEmojiSelected: ((category, emoji) {
                        setState(() {
                          _messageController.text =
                              _messageController.text + emoji.emoji;
                        });

                        if (!isShowSendButton) {
                          setState(() {
                            isShowSendButton = true;
                          });
                        }
                      }),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: hideEmojiContainer,
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
