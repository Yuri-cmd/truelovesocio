import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';
import 'package:truelovesocio/data/services/menu_service.dart';

class CreateMenuView extends StatefulWidget {
  const CreateMenuView({super.key});

  @override
  State<CreateMenuView> createState() => _CreateMenuViewState();
}

class _CreateMenuViewState extends State<CreateMenuView> {
  final SocioMenuController controller = Get.find<SocioMenuController>();
  final MenuService _menuService = Get.find<MenuService>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  
  final String _status = 'active';
  XFile? _image;
  int? _selectedCategoryId;
  bool _isSaving = false;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    
    _isPickingImage = true;
    try {
      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() => _image = pickedImage);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final socioId = _authController.socio.value?.id;
    if (socioId == null) {
      Get.snackbar("Error", "No se pudo identificar al socio");
      return;
    }

    if (_tituloController.text.isEmpty || _precioController.text.isEmpty || _selectedCategoryId == null || _image == null) {
      Get.snackbar("Error", "Por favor completa todos los campos y selecciona una imagen");
      return;
    }

    final precioStr = _precioController.text.replaceAll(',', '.');
    final precio = double.tryParse(precioStr);
    if (precio == null) {
      Get.snackbar("Error", "El precio ingresado no es válido");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _menuService.crearMenu(
        idEmpresa: socioId,
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        foto: _image!,
        precio: precio,
        status: _status,
        categoriaId: _selectedCategoryId!,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);
        Get.snackbar("Éxito", "Platillo creado correctamente");
      } else {
        final message = response.data?['message'] ?? "No se pudo crear el platillo";
        Get.snackbar("Error", message);
      }
    } catch (e) {
      String errorMessage = "No se pudo crear el platillo";
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        }
      } else {
        errorMessage = "Error: $e";
      }
      Get.snackbar("Error", errorMessage);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Platillo'), backgroundColor: Colors.red, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildTextField(_tituloController, 'Título', Icons.fastfood),
            const SizedBox(height: 15),
            _buildTextField(_descripcionController, 'Descripción', Icons.description, maxLines: 3),
            const SizedBox(height: 15),
            _buildTextField(_precioController, 'Precio', Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 15),
            _buildCategoryDropdown(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Platillo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: _image != null
            ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(_image!.path), fit: BoxFit.cover))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text('Seleccionar Imagen')],
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      if (controller.categories.isEmpty) {
        return const Text(
          "No tienes categorías creadas. Debes crear una primero.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
      }
      return DropdownButtonFormField<int>(
        initialValue: _selectedCategoryId,
        hint: const Text('Seleccionar Categoría'),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.category, color: Colors.red),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: controller.categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
        onChanged: (val) => setState(() => _selectedCategoryId = val),
      );
    });
  }
}
