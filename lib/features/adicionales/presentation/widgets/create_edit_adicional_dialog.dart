import 'package:flutter/material.dart';
import 'package:truelovesocio/data/models/adicional_model.dart';

/// Formulario de crear/editar un adicional. Devuelve (titulo, descripcion, precio) por onSave.
class CreateEditAdicionalDialog extends StatefulWidget {
  final Adicional? adicional;
  final Future<bool> Function(String titulo, String descripcion, double precio) onSave;

  const CreateEditAdicionalDialog({super.key, this.adicional, required this.onSave});

  @override
  State<CreateEditAdicionalDialog> createState() => _CreateEditAdicionalDialogState();
}

class _CreateEditAdicionalDialogState extends State<CreateEditAdicionalDialog> {
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.adicional?.titulo ?? '');
    _descripcionController = TextEditingController(text: widget.adicional?.descripcion ?? '');
    _precioController = TextEditingController(text: widget.adicional?.precio ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final titulo = _tituloController.text.trim();
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));

    if (titulo.isEmpty || precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y precio son requeridos')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(titulo, _descripcionController.text.trim(), precio);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.adicional != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Adicional' : 'Nuevo Adicional'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Ej: Queso extra, Salsa BBQ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio *', prefixText: 'S/ '),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
