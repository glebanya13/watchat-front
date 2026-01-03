import 'dart:io';
import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

void showSnackBar({required BuildContext context, required String content}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        top: 10,
        right: 10,
        left: 10,
        bottom: 0,
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<dynamic> pickImageFromGallery(BuildContext context) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage != null) {
      if (kIsWeb) {
        return pickedImage;
      } else {
        return File(pickedImage.path);
      }
    }
  } catch (e) {
    showSnackBar(context: context, content: 'Ошибка выбора изображения: ${e.toString()}');
  }
  return null;
}

Future<dynamic> pickVideoFromGallery(BuildContext context) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedVideo = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedVideo != null) {
      if (kIsWeb) {
        return pickedVideo;
      } else {
        return File(pickedVideo.path);
      }
    }
  } catch (e) {
    showSnackBar(context: context, content: 'Ошибка выбора файла: ${e.toString()}');
  }
  return null;
}

Future<dynamic> pickFileFromDevice(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      
      if (kIsWeb) {
        if (file.bytes != null) {
          return file;
        }
      } else {
        if (file.path != null) {
          return File(file.path!);
        }
      }
    }
  } catch (e) {
    showSnackBar(context: context, content: 'Ошибка выбора файла: ${e.toString()}');
  }
  return null;
}

Future<GiphyGif?> pickGIF(BuildContext context) async {
  GiphyGif? gif;
  try {
    gif = await Giphy.getGif(
      context: context,
      apiKey: 'pwXu0t7iuNVm8VO5bgND2NzwCpVH9S0F',
    );
  } catch (e) {
    showSnackBar(context: context, content: e.toString());
  }
  return gif;
}
