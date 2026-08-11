import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/data/models/promocion_model.dart';
import 'package:truelovesocio/features/promociones/controllers/promociones_controller.dart';

class CreateEditPromocionView extends StatefulWidget {
  final Promocion? promocion;

  const CreateEditPromocionView({super.key, this.promocion});

  @override
  State<CreateEditPromocionView> createState() => _CreateEditPromocionViewState();
}

class _CreateEditPromocionViewState extends State<CreateEditPromocionView> {
  final PromocionesController controller = Get.find<PromocionesController>();

  late final TextEditingController _tituloController;
  late final TextEditingController _subtituloController;

  bool _estado = true;
  XFile? _image;
  bool _isSaving = false;
  bool _isPickingImage = false;

  bool get _isEditing => widget.promocion != null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.promocion?.titulo ?? '');
    _subtituloController = TextEditingController(text: widget.promocion?.subtitulo ?? '');
    _estado = widget.promocion?.estado ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _subtituloController.dispose();
    super.dispose();
  }

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

    if (_tituloController.text.isEmpty || _subtituloController.text.isEmpty) {
      Get.snackbar("Error", "Por favor completa el título y el subtítulo");
      return;
    }

    if (!_isEditing && _image == null) {
      Get.snackbar("Error", "Selecciona una imagen para la promoción");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = _isEditing
          ? await controller.actualizarPromocion(
              id: widget.promocion!.id,
              titulo: _tituloController.text,
              subtitulo: _subtituloController.text,
              estado: _estado,
              imagen: _image,
            )
          : await controller.crearPromocion(
              titulo: _tituloController.text,
              subtitulo: _subtituloController.text,
              estado: _estado,
              imagen: _image,
            );

      if (success && mounted) {
        Get.back();
        Get.snackbar("Éxito", _isEditing ? "Promoción actualizada correctamente" : "Promoción creada correctamente");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Promoción' : 'Nueva Promoción'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Estas promociones aparecen en el carrusel de la app y, al presionarlas, '
              'llevan directo a tu restaurante.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildTextField(_tituloController, 'Título', Icons.title),
            const SizedBox(height: 15),
            _buildTextField(_subtituloController, 'Subtítulo', Icons.short_text, maxLines: 2),
            const SizedBox(height: 15),
            _buildEstadoSwitch(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar Promoción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
              )
            : (_isEditing && widget.promocion!.imagen.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.promocion!.imagen,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.image_outlined, size: 50, color: Colors.grey), Text('Seleccionar Imagen')],
                  ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildEstadoSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility, color: Colors.red[700]),
          const SizedBox(width: 10),
          Expanded(child: Text(_estado ? 'Activa' : 'Inactiva')),
          Switch(
            value: _estado,
            activeThumbColor: Colors.red,
            onChanged: (val) => setState(() => _estado = val),
          ),
        ],
      ),
    );
  }
}
