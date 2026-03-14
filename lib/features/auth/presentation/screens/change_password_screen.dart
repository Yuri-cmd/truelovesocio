import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/components/custom_button.dart';
import 'package:truelovesocio/components/custom_text_field.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';
import 'package:truelovesocio/data/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int id;
  const ChangePasswordScreen({super.key, required this.id});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final newPassword = _passwordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'La contraseña no puede estar vacía';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _authService.updatePassword(widget.id, newPassword);
      setState(() {
        _isLoading = false;
      });

      final data = response.data;
      _showAlert(data['message'], response.statusCode == 200);
    } catch (e) {
      setState(() { _isLoading = false; });
      _showAlert('Error de conexión', false);
    }
  }

  void _showAlert(String message, bool success) {
    Get.defaultDialog(
      title: success ? "Éxito" : "Error",
      middleText: message,
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        if (success) {
          Get.offAllNamed(Routes.LOGIN);
        }
      },
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
              const Text(
                'Cambia tu contraseña',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Nueva contraseña',
                prefixIcon: Icons.lock,
                obscureText: true,
                isPassword: false,
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "Guardar contraseña",
                  isLoading: _isLoading,
                  onPressed: _changePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
