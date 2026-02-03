import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importa el paquete de imagen
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/model/category_model.dart';

class CrearMenuView extends StatefulWidget {
  const CrearMenuView({super.key});

  @override
  State<CrearMenuView> createState() => _CrearMenuViewState();
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
      if (!mounted) return;
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
      if (!mounted) return;
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
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Información del Platillo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(255, 36, 36, 1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _tituloController,
                        decoration: InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Hamburguesa Doble',
                          prefixIcon: const Icon(
                            Icons.fastfood_outlined,
                            color: Color.fromRGBO(255, 36, 36, 1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(255, 36, 36, 1),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _descripcionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Ingredientes y detalles...',
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color.fromRGBO(255, 36, 36, 1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(255, 36, 36, 1),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _precioController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Precio',
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: Color.fromRGBO(255, 36, 36, 1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(255, 36, 36, 1),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _pickImage,
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _fotoController,
                            decoration: InputDecoration(
                              labelText: 'Foto del Platillo',
                              hintText: 'Selecciona una imagen',
                              prefixIcon: const Icon(
                                Icons.image_outlined,
                                color: Color.fromRGBO(255, 36, 36, 1),
                              ),
                              suffixIcon: const Icon(
                                Icons.upload_file,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _status,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color.fromRGBO(255, 36, 36, 1),
                                  ),
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
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedCategoryId,
                                  hint: const Text(
                                    'Categoría',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.category_outlined,
                                    color: Color.fromRGBO(255, 36, 36, 1),
                                  ),
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
                                              child: Text(
                                                category.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _crearMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 36, 36, 1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                          shadowColor: const Color.fromRGBO(255, 36, 36, 1),
                        ),
                        child: const Text(
                          'Crear Menú',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
