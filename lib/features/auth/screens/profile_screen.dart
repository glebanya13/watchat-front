import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watchat/common/api/api_client.dart';
import 'package:watchat/common/utils/colors.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/features/landing/screens/landing_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  dynamic selectedImage; 
  final TextEditingController nameController = TextEditingController();
  bool isEditing = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void selectImage() async {
    dynamic image = await pickImageFromGallery(context);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<ImageProvider?> _getImageProvider(dynamic selectedImage, String profilePic) async {
    if (selectedImage != null) {
      if (selectedImage is File) {
        return FileImage(selectedImage);
      } else if (kIsWeb && selectedImage is XFile) {
        Uint8List bytes = await selectedImage.readAsBytes();
        return MemoryImage(bytes);
      }
    } else if (profilePic.isNotEmpty) {
      return NetworkImage(profilePic);
    }
    return null;
  }

  void updateProfile() async {
    String name = nameController.text.trim();
    if (name.isEmpty) {
      showSnackBar(context: context, content: 'Имя не может быть пустым');
      return;
    }

    ref.read(authControllerProvider).updateUserProfile(
          context,
          name,
          selectedImage,
        );
    
    
    ref.invalidate(userDataAuthProvider);
    
    setState(() {
      isEditing = false;
      selectedImage = null;
    });
  }

  void signOut() async {
    try {
      // Удаляем токен из хранилища
      await ApiClient.setToken(null);
      
      // Инвалидируем провайдер пользователя
      ref.invalidate(userDataAuthProvider);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LandingScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context: context, content: 'Ошибка выхода: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataAuthProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Профиль'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
                userAsync.whenData((user) {
                  if (user != null) {
                    nameController.text = user.name;
                  }
                });
              },
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.invalidate(userDataAuthProvider);
            });
            return const SizedBox.shrink();
          }

          if (isEditing && nameController.text.isEmpty) {
            nameController.text = user.name;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      FutureBuilder<ImageProvider?>(
                        future: _getImageProvider(selectedImage, user.profilePic),
                        builder: (context, snapshot) {
                          return CircleAvatar(
                            radius: 64,
                            backgroundImage: snapshot.data,
                            child: snapshot.data == null
                                ? const Icon(Icons.person, size: 64)
                                : null,
                          );
                        },
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: -10,
                          left: 80,
                          child: IconButton(
                            onPressed: selectImage,
                            icon: const Icon(Icons.add_a_photo),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (isEditing)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.grey),
                    title: const Text('Номер телефона'),
                    subtitle: Text(user.phoneNumber),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.circle, color: Colors.green, size: 16),
                    title: const Text('Статус'),
                    subtitle: Text(user.isOnline ? 'В сети' : 'Не в сети'),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(size.width * 0.8, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (err, trace) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }
}

