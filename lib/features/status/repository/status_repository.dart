import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/models/status_model.dart';

final statusRepositoryProvider = Provider(
  (ref) => StatusRepository(),
);

class StatusRepository {
  StatusRepository();

  void uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        showSnackBar(context: context, content: 'Пользователь не авторизован');
        return;
      }

      // Загружаем изображение статуса
      List<int> fileBytes = await statusImage.readAsBytes();
      String fileName = statusImage.path.split('/').last;
      String imageUrl = await ApiService.uploadFile(fileBytes, 'status', fileName);

      // Получаем список контактов для определения whoCanSee
      List<String> whoCanSee = [];
      
      // В реальном приложении это должно быть через API
      // Пока используем пустой список whoCanSee - все контакты смогут видеть статус
      
      // Создаем или обновляем статус
      List<String> photoUrls = [imageUrl];
      
      // Получаем существующие статусы пользователя
      final statuses = await ApiService.getStatuses();
      final userStatuses = statuses.where((s) => s.uid == currentUser.uid).toList();
      
      if (userStatuses.isNotEmpty) {
        // Обновляем существующий статус
        photoUrls = [...userStatuses.first.photoUrl, imageUrl];
      }

      await ApiService.createStatus(photoUrls, whoCanSee: whoCanSee.isEmpty ? null : whoCanSee);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statusData = [];
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        return statusData;
      }

      // Получаем все статусы через API
      final allStatuses = await ApiService.getStatuses();
      
      // Получаем список пользователей с бэкенда для фильтрации статусов
      List<String> userPhoneNumbers = [];
      try {
        final users = await ApiService.getAllUsers();
        userPhoneNumbers = users.map((u) => u.phoneNumber.replaceAll(' ', '').replaceAll('+', '')).toList();
      } catch (e) {
        if (kDebugMode) print('Error getting users: $e');
      }

      // Фильтруем статусы: показываем только те, которые созданы в последние 24 часа
      final now = DateTime.now();
      for (var status in allStatuses) {
        // status.createdAt уже DateTime, не нужно конвертировать
        if (now.difference(status.createdAt).inHours <= 24) {
          // Проверяем, есть ли пользователь с таким номером телефона
          String statusPhone = status.phoneNumber.replaceAll(' ', '').replaceAll('+', '');
          bool isContact = userPhoneNumbers.contains(statusPhone);
          
          // Если статус для всех (whoCanSee пустой) или пользователь в списке whoCanSee
          if (isContact && (status.whoCanSee.isEmpty || status.whoCanSee.contains(currentUser.uid))) {
            statusData.add(status);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print(e);
      showSnackBar(context: context, content: e.toString());
    }
    return statusData;
  }
}
