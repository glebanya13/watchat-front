import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/models/chat_contact.dart';
import 'package:watchat/features/chat/screens/mobile_chat_screen.dart';

final selectContactsRepositoryProvider = Provider(
  (ref) => SelectContactRepository(),
);

class SelectContactRepository {
  SelectContactRepository();

  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    
    try {
      final users = await ApiService.getAllUsers();
      for (var user in users) {
        final contact = Contact(
          id: user.uid,
          displayName: user.name,
        );
        contact.phones.add(Phone(user.phoneNumber));
        contacts.add(contact);
      }
    } catch (e) {
    }
    
    return contacts;
  }

  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      if (selectedContact.phones.isEmpty) {
        showSnackBar(
          context: context,
          content: 'У этого контакта нет номера телефона.',
        );
        return;
      }

      // Получаем текущего пользователя для проверки
      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) {
        showSnackBar(context: context, content: 'Пользователь не авторизован');
        return;
      }

      String selectedPhoneNum = selectedContact.phones[0].number.replaceAll(' ', '').replaceAll('+', '');
      
      // Используем данные из Contact (который создан из UserModel с бэкенда)
      if (selectedContact.id.isNotEmpty) {
        // Получаем пользователя по ID (который является uid)
        final users = await ApiService.getAllUsers();
        final user = users.firstWhere(
          (u) => u.uid == selectedContact.id || 
                 u.phoneNumber.replaceAll(' ', '').replaceAll('+', '') == selectedPhoneNum,
          orElse: () => throw Exception('User not found'),
        );
        
        Navigator.pushNamed(
          context,
          MobileChatScreen.routeName,
          arguments: {
            'name': user.name,
            'uid': user.uid,
            'isGroupChat': false,
            'profilePic': user.profilePic,
          },
        );
        return;
      }
      
      // Если ID не найден, ищем через getChatContacts
      final contactsData = await ApiService.getChatContacts();
      
      // Ищем пользователя с таким номером телефона
      bool isFound = false;
      for (var contactData in contactsData) {
        final contact = ChatContact.fromMap(contactData);
        // Проверяем по contactId (который должен быть phoneNumber)
        if (contact.contactId == selectedPhoneNum || 
            contact.contactId.replaceAll(' ', '').replaceAll('+', '') == selectedPhoneNum) {
          isFound = true;
          Navigator.pushNamed(
            context,
            MobileChatScreen.routeName,
            arguments: {
              'name': contact.name,
              'uid': contact.contactId,
              'isGroupChat': false,
              'profilePic': contact.profilePic,
            },
          );
          break;
        }
      }

      if (!isFound) {
        // Если не нашли в чатах, пробуем найти в списке всех пользователей
        try {
          final users = await ApiService.getAllUsers();
          final user = users.firstWhere(
            (u) => u.phoneNumber.replaceAll(' ', '').replaceAll('+', '') == selectedPhoneNum,
            orElse: () => throw Exception('User not found'),
          );
          
          Navigator.pushNamed(
            context,
            MobileChatScreen.routeName,
            arguments: {
              'name': user.name,
              'uid': user.uid,
              'isGroupChat': false,
              'profilePic': user.profilePic,
            },
          );
        } catch (e) {
          showSnackBar(
            context: context,
            content: 'Этот номер не зарегистрирован в приложении.',
          );
        }
      }
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
