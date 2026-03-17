import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/components/custom_text_field.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final RxBool isButtonActive = false.obs;
  final RxBool _isObscure = true.obs;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    isButtonActive.value = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  void _togglePasswordVisibility() {
    _isObscure.value = !_isObscure.value;
  }

  void _login() async {
    String user = _emailController.text.trim();
    String password = _passwordController.text.trim();

    final result = await authController.loginWithQuota(user, password);

    if (result['success']) {
      final loginResponse = result['data'];
      final puedeAcceder = loginResponse['estado_cuota']['puede_acceder'] ?? false;
      final mensaje = loginResponse['estado_cuota']['mensaje'] ?? '';
      final diasVencimiento = loginResponse['estado_cuota']['dias_vencimiento'] ?? 0;
      final alerta = loginResponse['estado_cuota']['alerta'] ?? '';

      if (puedeAcceder) {
        Get.offAllNamed(Routes.HOME);

        if (alerta == 'critico' && mensaje.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _mostrarAlertaCuotaProximaVencer(mensaje, diasVencimiento);
          });
        }
      } else {
        // Permitir acceso pero irá directo a cuotas
        Get.offAllNamed(Routes.HOME);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.snackbar(
            "Acceso Restringido",
            mensaje.isNotEmpty ? mensaje : "Tienes pagos vencidos. Por favor, regulariza tu situación.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        });
      }
    } else {
      final errorData = result['data'];
      if (errorData != null && errorData['motivo'] == 'cuota_vencida') {
        // Incluso si el API lo devuelve como error 403/401 por cuota vencida,
        // si tenemos los datos del socio, podríamos intentar entrar.
        // Pero usualmente el API de login en 200 ya trae el estado_cuota.
        _mostrarAlertaCuotaVencida(errorData['message'] ?? 'Tienes pagos vencidos. Por favor, regulariza tu situación.');
      } else {
        Get.snackbar(
          "Error",
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _mostrarAlertaCuotaProximaVencer(String mensaje, int diasVencimiento) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.amber[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.amber[700], size: 30),
            const SizedBox(width: 10),
            const Text('Cuota Próxima a Vencer', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensaje, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Text(
                'Recuerda realizar tu pago antes del vencimiento para evitar suspensión de acceso.',
                style: TextStyle(fontSize: 14, color: Colors.amber[800], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white),
            child: const Text('Entendido'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _mostrarAlertaCuotaVencida(String motivo) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red[700], size: 30),
            const SizedBox(width: 10),
            const Text('Acceso Denegado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(motivo, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Text(
                'Contacta al administrador para regularizar tu situación.',
                style: TextStyle(fontSize: 14, color: Colors.red[800], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('images/logo.png', height: 30),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                    child: const Text('Portal', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestiona tu negocio desde la palma de tu mano',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicia sesión con tu correo electrónico',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(controller: _emailController, hintText: 'Usuario', isPassword: false),
                    const SizedBox(height: 15),
                    Obx(() => CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      obscureText: _isObscure.value,
                      onIconPressed: _togglePasswordVisibility,
                      isPassword: true,
                    )),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed(Routes.EMAIL_VERIFY),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() => ElevatedButton(
                        onPressed: isButtonActive.value && !authController.isLoading.value ? _login : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: isButtonActive.value ? Colors.white : colorScheme.onSurface,
                          backgroundColor: isButtonActive.value ? Colors.red : colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: authController.isLoading.value
                            ? const SpinKitCircle(color: Colors.white, size: 30.0)
                            : Text(
                                'Iniciar sesión',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isButtonActive.value ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                      )),
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
