import 'package:flutter/material.dart';
import 'package:truelovesocio/model/category_model.dart';
import 'package:truelovesocio/screen/add_edit_category_screen.dart';
import 'package:truelovesocio/service/api_service.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final ApiService _apiService = ApiService();

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

  // Navegar a la pantalla de agregar/editar
  Future<void> _navigateToAddEditCategory({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditCategory(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),

                        title: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        subtitle:
                            category.horarios.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        category.horarios.map((schedule) {
                                          if (!schedule.isActive) {
                                            return const SizedBox();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2.0,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 70,
                                                  child: Text(
                                                    schedule.day,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    (schedule.startTime ==
                                                                null ||
                                                            schedule.endTime ==
                                                                null)
                                                        ? 'Disponible 24 horas'
                                                        : '${schedule.startTime} - ${schedule.endTime}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                )
                                : const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Disponible 24 horas',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF1E88E5),
                                ),
                                onPressed:
                                    () => _navigateToAddEditCategory(
                                      category: category,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: category.estado == 1,
                                  activeColor: const Color(0xFF4CAF50),
                                  activeTrackColor: const Color(0xFFC8E6C9),
                                  inactiveThumbColor: const Color(0xFFEF5350),
                                  inactiveTrackColor: const Color(0xFFFFCDD2),
                                  onChanged: (val) async {
                                    final nuevoEstado = val ? 1 : 0;
                                    try {
                                      await _apiService.updateCategoryStatus(
                                        category.id,
                                        nuevoEstado,
                                      );
                                      setState(() {
                                        category.estado = nuevoEstado;
                                      });
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al cambiar el estado: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
