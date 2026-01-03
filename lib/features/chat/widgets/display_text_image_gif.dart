import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'package:watchat/common/enums/message_enum.dart';
import 'package:watchat/common/api/api_client.dart';
import 'package:watchat/features/chat/widgets/video_player_item.dart';

class DisplayTextImageGIF extends StatelessWidget {
  final String message;
  final MessageEnum type;
  const DisplayTextImageGIF({
    Key? key,
    required this.message,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();

    return type == MessageEnum.text
        ? Text(
            message,
            style: const TextStyle(
              fontSize: 16,
            ),
          )
        : type == MessageEnum.audio
            ? StatefulBuilder(builder: (context, setState) {
                return IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 100,
                  ),
                  onPressed: () async {
                    if (isPlaying) {
                      await audioPlayer.pause();
                      setState(() {
                        isPlaying = false;
                      });
                    } else {
                      await audioPlayer.play(UrlSource(message));
                      setState(() {
                        isPlaying = true;
                      });
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                  ),
                );
              })
            : type == MessageEnum.video
                ? VideoPlayerItem(
                    videoUrl: message,
                  )
                : type == MessageEnum.gif
                    ? CachedNetworkImage(
                        imageUrl: message,
                      )
                : type == MessageEnum.file
                    ? _buildFileWidget(message)
                    : CachedNetworkImage(
                        imageUrl: message,
                      );
  }

  Widget _buildFileWidget(String fileUrl) {
    // Определяем тип файла по расширению
    final isImage = fileUrl.toLowerCase().endsWith('.jpg') ||
        fileUrl.toLowerCase().endsWith('.jpeg') ||
        fileUrl.toLowerCase().endsWith('.png') ||
        fileUrl.toLowerCase().endsWith('.gif') ||
        fileUrl.toLowerCase().endsWith('.webp');
    
    final fileName = fileUrl.split('/').last;
    final fileExtension = fileName.contains('.') 
        ? fileName.split('.').last.toUpperCase() 
        : 'FILE';

    // Если это изображение, показываем его как изображение с возможностью скачать
    if (isImage) {
      final fullUrl = fileUrl.startsWith('http') 
          ? fileUrl 
          : '${ApiClient.baseUrl}$fileUrl';
      
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                width: 150,
                height: 150,
                placeholder: (context, url) => Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: const SizedBox.shrink(),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                onPressed: () async {
                  final uri = Uri.parse(fullUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Скачать изображение',
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ),
          ),
          ],
        ),
      );
    }

    // Для остальных файлов показываем карточку с информацией
    // Обрезаем название файла до 10 символов (в два раза меньше)
    final displayName = fileName.length > 10 
        ? '${fileName.substring(0, 10)}...' 
        : fileName;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 200, // Уменьшено в два раза
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка файла
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                size: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 6),
            // Информация о файле
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    fileExtension,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Кнопка скачивания
            IconButton(
              onPressed: () async {
                final fullUrl = fileUrl.startsWith('http') 
                    ? fileUrl 
                    : '${ApiClient.baseUrl}$fileUrl';
                final uri = Uri.parse(fullUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(
                Icons.download,
                color: Colors.blue,
                size: 24,
              ),
              tooltip: 'Скачать файл',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
