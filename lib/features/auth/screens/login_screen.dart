import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/utils/colors.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/common/widgets/custom_button.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    int selectionIndex = newValue.selection.baseOffset;
    
    // Всегда начинаем с +7
    if (!newText.startsWith('+7')) {
      // Извлекаем только цифры
      String digits = newText.replaceAll(RegExp(r'[^0-9]'), '');
      newText = '+7$digits';
      selectionIndex = newText.length;
    } else {
      // Если начинается с +7, проверяем что пользователь не пытается удалить +7
      if (newText.length < 2 || !newText.startsWith('+7')) {
        String digits = newText.replaceAll(RegExp(r'[^0-9]'), '');
        newText = '+7$digits';
        selectionIndex = newText.length;
      } else {
        // Оставляем +7 и только цифры после
        String prefix = '+7';
        String digits = newText.substring(2).replaceAll(RegExp(r'[^0-9]'), '');
        newText = '$prefix$digits';
        
        // Корректируем позицию курсора
        if (selectionIndex < 2) {
          selectionIndex = 2;
        } else if (selectionIndex > newText.length) {
          selectionIndex = newText.length;
        }
      }
    }
    
    // Ограничиваем длину (максимум 12 символов: +7 + 10 цифр)
    if (newText.length > 12) {
      newText = newText.substring(0, 12);
      if (selectionIndex > 12) {
        selectionIndex = 12;
      }
    }
    
    // Гарантируем что курсор не может быть перед +7
    if (selectionIndex < 2) {
      selectionIndex = 2;
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем +7 в поле ввода
    phoneController.text = '+7';
  }

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
  }


  void sendPhoneNumber() {
    String phoneNumber = phoneController.text.trim();
    
    // Проверяем, что номер начинается с +7 и содержит достаточно цифр
    if (!phoneNumber.startsWith('+7')) {
      showSnackBar(context: context, content: 'Номер должен начинаться с +7');
      return;
    }
    
    // Извлекаем цифры после +7
    String digits = phoneNumber.substring(2);
    
    if (digits.isEmpty || digits.length < 10) {
      showSnackBar(context: context, content: 'Пожалуйста, введите полный номер телефона');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Отправляем номер с +7
    ref
        .read(authControllerProvider)
        .signInWithPhone(context, phoneNumber)
        .then((_) {
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((error) {
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Введите номер телефона',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: size.width * 0.8,
                  child: SizedBox(
                    height: 56, 
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        _PhoneNumberFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'номер телефона',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.4),
                SizedBox(
                  width: 120,
                  child: CustomButton(
                    onPressed: _isLoading ? null : sendPhoneNumber,
                    text: 'ДАЛЕЕ',
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
