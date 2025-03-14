// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Importa el paquete SpinKit
import 'package:truelovesocio/components/custom_text_field.dart';
import 'package:truelovesocio/models/socio_model.dart';
import 'package:truelovesocio/screen/home_screen.dart';
import 'package:truelovesocio/service/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isButtonActive = false;
  bool _isObscure = true;
  bool _isLoading = false; // Variable para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonActive =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  // Cambia el estado de la visibilidad de la contraseña
  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure; // Cambiar la visibilidad
    });
  }

  void _login() async {
    setState(() => _isLoading = true);

    String user = _emailController.text.trim();
    String password = _passwordController.text.trim();

    Socio? conductor = await ApiService.login(user, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (conductor != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Credenciales incorrectas")));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE5EB),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black,
        backgroundColor: const Color(0xFFFDE5EB),
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // CircleAvatar with Gray Border
              Row(
                children: [
                  Image.asset(
                    'images/logo.png', // Logo
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Row(
                children: [
                  Icon(Icons.language, color: Colors.black),
                  SizedBox(width: 4),
                  Text('ES', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestiona tu negocio desde la palma de tu mano',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inicia sesión con tu correo electrónico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Campo de correo electrónico
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Correo Electrónico',
                      isPassword: false,
                    ),
                    const SizedBox(height: 15),
                    // Campo de contraseña
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      obscureText: _isObscure,
                      onIconPressed: _togglePasswordVisibility,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),
                    // Enlace "¿Olvidaste tu contraseña?"
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botón de iniciar sesión con SpinKit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isButtonActive && !_isLoading
                                ? _login // Llamamos a la función de login
                                : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              isButtonActive ? Colors.white : Colors.grey,
                          backgroundColor:
                              isButtonActive ? Colors.red : Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SpinKitCircle(
                                  // Mostramos el SpinKit si está cargando
                                  color: Colors.white,
                                  size: 30.0,
                                )
                                : const Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
