import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      foregroundColor: colorScheme.onSurface,
      backgroundColor: colorScheme.surface,
      title: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // CircleAvatar with Gray Border
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest, // Border color
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    // Aquí puedes manejar lo que pasa cuando seleccionas "Mi perfil"
                    // Ejemplo: Navegar a una nueva pantalla
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          const Text('Mi perfil'),
                        ],
                      ),
                    ),
                    // Agrega más elementos al menú si es necesario
                  ];
                },
                // Usamos offset para que el menú se despliegue debajo del CircleAvatar
                offset: const Offset(
                  0,
                  50,
                ), // Cambia el valor según la distancia que quieras
                child: CircleAvatar(
                  backgroundColor: colorScheme.surface,
                  child: Text(
                    'JS',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2.0), // Border thickness
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest, // Border color
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: Icon(Icons.notifications, color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Define the preferredSize getter to specify the height of the app bar
  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
