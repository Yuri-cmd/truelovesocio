import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/components/custom_button.dart';
import 'package:truelovesocio/components/custom_text_field.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';
import 'package:truelovesocio/data/services/auth_service.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  int? _userId;
  String? _codigoCorrecto;
  bool _codeSent = false;

  void _handleAction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (!_codeSent) {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Este campo no puede estar vacío';
          _isLoading = false;
        });
        return;
      }

      try {
        final response = await _authService.sendCode(input);
        setState(() {
          _isLoading = false;
        });

        final data = response.data;
        if (response.statusCode == 200 && data['success'] == true) {
          setState(() {
            _userId = data['id'];
            _codigoCorrecto = data['verification_code']?.toString();
            _codeSent = true;
          });
          _showMessage(data['message'], true);
        } else {
          _showMessage(data['message'] ?? 'Error al enviar código', false);
        }
      } catch (e) {
        setState(() { _isLoading = false; });
        _showMessage('Error de conexión', false);
      }
    } else {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() {
          _errorMessage = 'Ingresa el código';
          _isLoading = false;
        });
        return;
      }

      if (code == _codigoCorrecto) {
        Get.toNamed(Routes.CHANGE_PASSWORD, arguments: _userId);
      } else {
        setState(() {
          _errorMessage = 'Código incorrecto';
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, bool success) {
    Get.defaultDialog(
      title: success ? 'Éxito' : 'Error',
      middleText: message,
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png', height: 120),
              const SizedBox(height: 20),
              Text(
                _codeSent ? 'Ingresa el código' : 'Recuperar contraseña',
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!_codeSent)
                CustomTextField(
                  controller: _inputController,
                  hintText: 'Correo electrónico',
                  prefixIcon: Icons.email,
                  isPassword: false,
                ),
              if (_codeSent)
                CustomTextField(
                  controller: _codeController,
                  hintText: 'Código de 4 dígitos',
                  prefixIcon: Icons.lock_clock,
                  isPassword: false,
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: _codeSent ? 'Verificar código' : 'Enviar código',
                  isLoading: _isLoading,
                  onPressed: _handleAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
