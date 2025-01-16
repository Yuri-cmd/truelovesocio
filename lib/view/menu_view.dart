import 'package:flutter/material.dart';
import 'package:truelovesocio/components/components.dart';
import 'package:truelovesocio/model/menu_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/view/category_view.dart';
import 'package:truelovesocio/view/crear_menu_view.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  // Lista de menús
  List<Menu> dishes = [];

  // Cargar los menús al iniciar la vista
  @override
  void initState() {
    super.initState();
    ApiService()
        .fetchMenu()
        .then((menus) {
          setState(() {
            dishes = menus;
          });
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los menús: $e')),
          );
        });
  }

  // Función para cambiar el estado del platillo
  void _toggleDishStatus(Menu dish, bool isActive) {
    ApiService()
        .updateDishStatus(dish.id, isActive)
        .then((_) {
          setState(() {
            dish.status = isActive ? 'active' : 'inactive';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estado del platillo actualizado')),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el estado: $e')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Opciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Producto', // Título principal
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 4,
                  ), // Espacio entre el título y el subtítulo

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Cierra el Drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryView(),
                        ), // Navega a la vista de Categorías
                      );
                    },
                    child: const Text(
                      'Categorías', // Subtítulo 1
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4), // Espacio entre los subtítulos

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Cierra el Drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryView(),
                        ), // Navega a la vista Adicional
                      );
                    },
                    child: const Text(
                      'Adicional', // Subtítulo 2
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Aquí puedes agregar una acción adicional si lo necesitas
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main Container
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Menú',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: 'Menú Almuerzo',
                          items:
                              ['Menú Almuerzo', 'Menú Cena'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {},
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Recargar los menús al presionar el botón
                            ApiService()
                                .fetchMenu()
                                .then((menus) {
                                  setState(() {
                                    dishes = menus;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Menú actualizado'),
                                    ),
                                  );
                                })
                                .catchError((e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al recargar los menús: $e',
                                      ),
                                    ),
                                  );
                                });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Cambios'),
                        ),
                      ],
                    ),
                    // Dish Category Title
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Platos principales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Dish List
                    Expanded(
                      child: ListView.builder(
                        itemCount: dishes.length,
                        itemBuilder: (context, index) {
                          final dish = dishes[index];
                          return DishItemWidget(
                            name: dish.titulo,
                            price: dish.precio,
                            isActive: dish.status == 'active',
                            imageUrl:
                                "https://magusemail.com/truelove-back/public/${dish.foto}", // Imagen predeterminada
                            onToggle: (val) {
                              _toggleDishStatus(dish, val);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrearMenuView(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.add, color: Colors.white)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
