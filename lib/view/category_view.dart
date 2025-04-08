import 'package:flutter/material.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/model/category_model.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final ApiService _apiService = ApiService();
  final TextEditingController _categoryController = TextEditingController();

  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Cargar categorías desde la API
  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await _apiService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las categorías: $e')),
      );
    }
  }

  // Agregar una nueva categoría
  Future<void> _addCategory() async {
    if (_categoryController.text.isNotEmpty) {
      try {
        await _apiService.createCategory(_categoryController.text);
        _categoryController.clear();
        _loadCategories(); // Recargar las categorías después de agregar una nueva
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la categoría: $e')),
        );
      }
    }
  }

  // Eliminar una categoría
  Future<void> _deleteCategory(int id) async {
    try {
      await _apiService.deleteCategory(id);
      _loadCategories(); // Recargar las categorías después de eliminar una
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la categoría: $e')),
      );
    }
  }

  // Mostrar el cuadro de diálogo para agregar una categoría
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Categoría'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: 'Nombre de la categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addCategory();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar el cuadro de diálogo para editar una categoría
  void _showEditCategoryDialog(int categoryId, String initialName) {
    _categoryController.text =
        initialName; // Establecer el valor inicial del campo
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: 'Nombre de la categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateCategory(categoryId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  // Función para actualizar la categoría
  Future<void> _updateCategory(int categoryId) async {
    if (_categoryController.text.isNotEmpty) {
      try {
        await _apiService.updateCategory(categoryId, _categoryController.text);
        _categoryController.clear();
        _loadCategories(); // Recargar las categorías después de la actualización
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la categoría: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator()) // Cargando...
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              title: Text(
                                category.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _showEditCategoryDialog(
                                          category.id,
                                          category.name,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _deleteCategory(category.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment:
                          Alignment.centerRight, // Alinea el botón a la derecha
                      child: ElevatedButton(
                        onPressed:
                            _showAddCategoryDialog, // Mostrar el cuadro de agregar categoría
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.add, // Icono de '+'
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
