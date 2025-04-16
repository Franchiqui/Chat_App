import 'package:flutter/material.dart';

Future<String?> showGroupNameDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nombre del grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Introduce el nombre del grupo'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Crear'),
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.of(context).pop(nombre);
              }
            },
          ),
        ],
      );
    },
  );
}
