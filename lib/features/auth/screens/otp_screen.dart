import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/utils/colors.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';

class OTPScreen extends ConsumerStatefulWidget {
  static const String routeName = '/otp-screen';
  final String phoneNumber;
  const OTPScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _otpCode = '';

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      
      String code = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (code.length >= 6) {
        
        for (int i = 0; i < 6 && i < code.length; i++) {
          _controllers[i].text = code[i];
        }
        _focusNodes[5].unfocus();
        _updateOTP();
        return;
      } else if (code.isNotEmpty) {
        
        for (int i = 0; i < code.length && (index + i) < 6; i++) {
          _controllers[index + i].text = code[i];
        }
        int nextIndex = (index + code.length).clamp(0, 5);
        _focusNodes[nextIndex].requestFocus();
        _updateOTP();
        return;
      }
      
      _controllers[index].text = value[0];
    }
    
    if (value.isNotEmpty && index < 5) {
      
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      
      _focusNodes[index - 1].requestFocus();
    }
    
    _updateOTP();
  }


  void _updateOTP() {
    _otpCode = _controllers.map((controller) => controller.text).join();
    if (_otpCode.length == 6) {
      verifyOTP(ref, context, _otpCode);
    }
  }

  void verifyOTP(WidgetRef ref, BuildContext context, String userOTP) {
    ref.read(authControllerProvider).verifyOTP(
          context,
          widget.phoneNumber,
          userOTP,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Подтверждение номера',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Мы отправили SMS с кодом.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: tabColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(index, value),
                      onTap: () {
                        
                        _controllers[index].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[index].text.length,
                        );
                      },
                      onSubmitted: (value) {
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
