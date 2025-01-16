import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importa el paquete de imagen
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/model/category_model.dart';

class CrearMenuView extends StatefulWidget {
  const CrearMenuView({Key? key}) : super(key: key);

  @override
  _CrearMenuViewState createState() => _CrearMenuViewState();
}

class _CrearMenuViewState extends State<CrearMenuView> {
  final ApiService _apiService = ApiService();

  List<Category> categories = [];
  int? selectedCategoryId;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();

  String _status = 'active'; // Valor por defecto
  XFile? _image; // Variable para almacenar la imagen seleccionada

  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Cargar las categorías desde la API
  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await _apiService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las categorías: $e')),
      );
    }
  }

  // Función para seleccionar la imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
        _fotoController.text = _image!.path; // Establecer la ruta de la imagen
      });
    }
  }

  // Crear el menú y asociarlo con la categoría seleccionada
  Future<void> _crearMenu() async {
    final titulo = _tituloController.text;
    final descripcion = _descripcionController.text;
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    final foto = _image; // Usar la imagen seleccionada en lugar de la ruta

    if (titulo.isEmpty ||
        descripcion.isEmpty ||
        precio <= 0 ||
        foto == null || // Verificar si la imagen fue seleccionada
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    try {
      await _apiService.crearMenu(
        titulo,
        descripcion,
        foto, // Pasar el archivo de la imagen
        precio,
        _status,
        selectedCategoryId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menú creado correctamente')),
      );
      // Limpiar los campos después de la creación
      _tituloController.clear();
      _descripcionController.clear();
      _precioController.clear();
      setState(() {
        selectedCategoryId = null;
        _image = null; // Limpiar la imagen seleccionada
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear el menú: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Menú')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _precioController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // inputFormatters: [
                      //   // Restringir el precio a solo decimales
                      //   FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?')),
                      // ],
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _fotoController,
                          decoration: const InputDecoration(
                            labelText: 'Foto (URL o Seleccionar Imagen)',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactivo'),
                        ),
                        DropdownMenuItem(
                          value: 'out-of-stock',
                          child: Text('Agotado'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<int>(
                      value: selectedCategoryId,
                      hint: const Text('Seleccionar Categoría'),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      items:
                          categories
                              .map(
                                (category) => DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _crearMenu,
                      child: const Text('Crear Menú'),
                    ),
                  ],
                ),
      ),
    );
  }
}
