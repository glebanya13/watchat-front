import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_client.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/features/auth/repository/auth_repository.dart';
import 'package:watchat/models/user_model.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider<UserModel?>((ref) async {
  final token = await ApiClient.getToken();
  // Если токена нет, сразу возвращаем null без запроса
  if (token == null || token.isEmpty) {
    return null;
  }
  
  try {
    // Используем ApiService напрямую, чтобы избежать циклической зависимости
    final user = await ApiService.getCurrentUser();
    // Если получили null и статус был 401, токен уже удален в ApiClient
    return user;
  } catch (e) {
    // Если ошибка, удаляем токен на всякий случай
    await ApiClient.setToken(null);
    return null;
  }
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;
  AuthController({
    required this.authRepository,
    required this.ref,
  });

  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  Future<void> signInWithPhone(BuildContext context, String phoneNumber) {
    return authRepository.signInWithPhone(context, phoneNumber);
  }

  void verifyOTP(BuildContext context, String phoneNumber, String userOTP) {
    authRepository.verifyOTP(
      context: context,
      phoneNumber: phoneNumber,
      userOTP: userOTP,
    );
  }

  void saveUserData(
      BuildContext context, String name, dynamic profilePic) {
    authRepository.saveUserData(
      name: name,
      profilePic: profilePic,
      context: context,
    );
  }

  Stream<UserModel> userDataById(String userId) {
    return authRepository.userData(userId);
  }

  void setUserState(bool isOnline) {
    authRepository.setUserState(isOnline);
  }

  void updateUserProfile(
      BuildContext context, String name, dynamic profilePic) {
    authRepository.updateUserProfile(
      name: name,
      profilePic: profilePic,
      context: context,
    );
  }
}
