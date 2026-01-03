import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/utils/utils.dart';

final groupRepositoryProvider = Provider(
  (ref) => GroupRepository(ref: ref),
);

class GroupRepository {
  final ProviderRef ref;
  
  GroupRepository({
    required this.ref,
  });

  void createGroup(BuildContext context, String name, dynamic profilePic, 
      List<Contact> selectedContact) async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        showSnackBar(context: context, content: 'Пользователь не авторизован');
        return;
      }

      // Получаем список пользователей из контактов
      List<String> memberUids = [currentUser.uid];
      
      // Извлекаем UID из выбранных контактов
      for (var contact in selectedContact) {
        // На веб-платформе contact.id уже содержит uid
        // На мобильных платформах нужно получить uid из номера телефона
        if (contact.id.isNotEmpty) {
          // Используем id контакта как uid (для веб-платформы)
          memberUids.add(contact.id);
        } else if (contact.phones.isNotEmpty) {
          // Для мобильных платформ нормализуем номер телефона
          String phoneNumber = contact.phones[0].number.replaceAll(' ', '').replaceAll('+', '');
          memberUids.add(phoneNumber);
        }
      }
      
      // Загружаем фото группы если есть
      String? groupPicUrl;
      if (profilePic != null) {
        List<int> fileBytes;
        String fileName = 'group_pic';
        
        if (profilePic is File) {
          fileBytes = await profilePic.readAsBytes();
          fileName = profilePic.path.split('/').last;
        } else {
          showSnackBar(context: context, content: 'Неподдерживаемый тип файла');
          return;
        }
        
        groupPicUrl = await ApiService.uploadFile(fileBytes, 'groups', fileName);
      }

      // Создаем группу через API
      await ApiService.createGroup(name, groupPicUrl, memberUids);
      
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
