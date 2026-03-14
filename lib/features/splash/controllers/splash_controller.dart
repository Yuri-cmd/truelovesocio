import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';
import 'package:truelovesocio/data/services/version_check_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:truelovesocio/core/theme/app_theme.dart';

class SplashController extends GetxController {
  final VersionCheckService _versionService = VersionCheckService();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final versionInfo = await _versionService.checkVersion();

    if (versionInfo['needsUpdate'] == true && versionInfo['forceUpdate'] == true) {
      _showUpdateDialog(versionInfo['updateUrl'], true);
    } else {
      _checkLogin();
    }
  }

  Future<void> _checkLogin() async {
    await _authController.loadSavedUser();
    if (_authController.isLoggedIn) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  void _showUpdateDialog(String url, bool isMandatory) {
    Get.dialog(
      AlertDialog(
        title: const Text('Actualización Necesaria'),
        content: const Text(
          'Hay una nueva versión obligatoria disponible. Por favor, actualiza la aplicación para continuar.',
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Más tarde'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text(
              'Actualizar ahora',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: !isMandatory,
    );
  }
}
