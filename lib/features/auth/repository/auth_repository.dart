import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_client.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/features/auth/screens/otp_screen.dart';
import 'package:watchat/features/auth/screens/user_information_screen.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/models/user_model.dart';
import 'package:watchat/mobile_layout_screen.dart';


final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref: ref),
);

class AuthRepository {
  final ProviderRef ref;
  
  AuthRepository({required this.ref});

  Future<UserModel?> getCurrentUserData() async {
    try {
      return await ApiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<void> signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.isEmpty) {
        showSnackBar(context: context, content: 'Пожалуйста, введите номер телефона');
        return;
      }
      
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }
      
      String digitsOnly = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < 10) {
        showSnackBar(context: context, content: 'Номер телефона слишком короткий. Проверьте правильность ввода.');
        return;
      }
      if (digitsOnly.length > 15) {
        showSnackBar(context: context, content: 'Номер телефона слишком длинный. Проверьте правильность ввода.');
        return;
      }
      
      // TEST MODE: Автоматически отправляем код и верифицируем
      // Отправляем код через API
      final result = await ApiService.sendVerificationCode(formattedPhone);
      
      if (result['success'] == true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await verifyOTP(context: context, phoneNumber: formattedPhone, userOTP: '111111');
      } else {
        showSnackBar(context: context, content: result['message'] ?? 'Ошибка отправки кода');
      }
    } catch (e) {
      showSnackBar(context: context, content: 'Произошла ошибка: ${e.toString()}');
    }
  }

  Future<void> verifyOTP({
    required BuildContext context,
    required String phoneNumber,
    required String userOTP,
  }) async {
    try {
      final result = await ApiService.verifyCode(phoneNumber, userOTP);
      
      if (result['token'] != null) {
        await ApiClient.setToken(result['token']);
        await Future.delayed(const Duration(milliseconds: 300));
        
        final savedToken = await ApiClient.getToken();
        if (savedToken == null || savedToken.isEmpty) {
          showSnackBar(context: context, content: 'Ошибка сохранения токена');
          return;
        }
        
        ref.invalidate(userDataAuthProvider);
        await Future.delayed(const Duration(milliseconds: 700));
        
        // Бэкенд возвращает информацию о пользователе в ответе verifyCode
        // Если user есть в ответе и не null - пользователь уже существует, идем в приложение
        // Если user null - нужно создать пользователя
        final userData = result['user'];
        
        // Проверяем, что userData не null и содержит данные
        if (userData != null && userData is Map && userData['uid'] != null) {
          // Пользователь существует, переходим в приложение
          await Future.delayed(const Duration(milliseconds: 300));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MobileLayoutScreen(),
            ),
            (route) => false,
          );
        } else {
          // Пользователь не существует, нужно создать профиль
          Navigator.pushNamedAndRemoveUntil(
            context,
            UserInformationScreen.routeName,
            (route) => false,
          );
        }
      } else {
        showSnackBar(context: context, content: 'Неверный код верификации');
      }
    } catch (e) {
      showSnackBar(context: context, content: 'Произошла ошибка при проверке кода: ${e.toString()}');
    }
  }

  void saveUserData({
    required String name,
    required dynamic profilePic, 
    required BuildContext context,
  }) async {
    try {
      // Проверяем наличие токена перед созданием пользователя
      final token = await ApiClient.getToken();
      if (token == null || token.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login-screen',
          (route) => false,
        );
        return;
      }
      
      String photoUrl = '';
      
      if (profilePic != null) {
        try {
          List<int> fileBytes;
          String fileName = 'profile_pic';
          
          if (profilePic is File) {
            fileBytes = await profilePic.readAsBytes();
            fileName = profilePic.path.split('/').last;
          } else {
            if (context.mounted) {
              showSnackBar(context: context, content: 'Неподдерживаемый тип файла');
            }
            return;
          }
          
          photoUrl = await ApiService.uploadFile(fileBytes, 'profilePic', fileName);
        } catch (e) {
          if (context.mounted) {
            showSnackBar(context: context, content: 'Ошибка загрузки фото: ${e.toString()}');
          }
          return;
        }
      }

      final tokenBeforeCreate = await ApiClient.getToken();
      if (tokenBeforeCreate == null || tokenBeforeCreate.isEmpty) {
        showSnackBar(context: context, content: 'Токен авторизации потерян. Пожалуйста, войдите снова.');
        return;
      }
      
      final createdUser = await ApiService.createUser(name, photoUrl.isEmpty ? null : photoUrl);
      
      final tokenAfterCreate = await ApiClient.getToken();
      if (tokenAfterCreate == null || tokenAfterCreate.isEmpty) {
        if (context.mounted) {
          showSnackBar(context: context, content: 'Токен потерян после создания пользователя');
        }
        return;
      }
      
      if (createdUser == null) {
        if (context.mounted) {
          showSnackBar(context: context, content: 'Ошибка: пользователь не был создан');
        }
        return;
      }
      
      ref.invalidate(userDataAuthProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MobileLayoutScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context: context, 
          content: 'Ошибка создания профиля: ${e.toString()}',
        );
      }
    }
  }

  Stream<UserModel> userData(String userId) {
    // Для real-time обновлений нужно использовать WebSocket
    // Пока возвращаем периодические обновления
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      // Проверяем наличие токена перед запросом
      final token = await ApiClient.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      final user = await ApiService.getCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }
      return user;
    }).asyncMap((future) => future);
  }

  void setUserState(bool isOnline) async {
    try {
      await ApiService.setUserOnlineStatus(isOnline);
    } catch (e) {
    }
  }

  void updateUserProfile({
    required String name,
    required dynamic profilePic, 
    required BuildContext context,
  }) async {
    try {
      String? photoUrl;
      
      if (profilePic != null) {
        // Читаем файл в байты
        List<int> fileBytes;
        String fileName = 'profile_pic';
        
        if (profilePic is File) {
          fileBytes = await profilePic.readAsBytes();
          fileName = profilePic.path.split('/').last;
        } else {
          showSnackBar(context: context, content: 'Неподдерживаемый тип файла');
          return;
        }
        
        // Загружаем через API
        photoUrl = await ApiService.uploadFile(fileBytes, 'profilePic', fileName);
      }

      await ApiService.updateUser(name, photoUrl);
      
      showSnackBar(context: context, content: 'Профиль обновлен');
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
