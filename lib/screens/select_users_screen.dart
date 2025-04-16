import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../utils/chat_utils.dart';
import 'chat_screen.dart';

class SelectUsersScreen extends StatefulWidget {
  final void Function(List<UserModel>) onSelectionConfirmed;
  final String currentUserId;
  final int? maxSeleccion; // Si es 1, solo permite seleccionar un usuario (modo chat)

  const SelectUsersScreen({
    Key? key,
    required this.onSelectionConfirmed,
    required this.currentUserId,
    this.maxSeleccion,
  }) : super(key: key);

  @override
  State<SelectUsersScreen> createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends State<SelectUsersScreen> {
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    // Cargar usuarios al entrar en la pantalla
    Provider.of<UserProvider>(context, listen: false).cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final usuarios = userProvider.usuarios
        .where((u) => u.id != widget.currentUserId)
        .toList(); // Excluir al usuario actual

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona usuarios para el grupo'),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usuarios.isEmpty
              ? const Center(child: Text('No hay usuarios disponibles.'))
              : ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    return CheckboxListTile(
                      value: _selectedUserIds.contains(usuario.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            if (widget.maxSeleccion == 1) {
                              // Solo uno permitido, limpia y agrega el nuevo
                              _selectedUserIds
                                ..clear()
                                ..add(usuario.id);
                            } else {
                              _selectedUserIds.add(usuario.id);
                            }
                          } else {
                            _selectedUserIds.remove(usuario.id);
                          }
                        });
                      },
                      title: Text(usuario.displayName_A.isNotEmpty
                          ? usuario.displayName_A
                          : usuario.username),
                      subtitle: Text(usuario.username),
                      secondary: usuario.avatar != null && usuario.avatar!.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(usuario.avatar!))
                          : const CircleAvatar(child: Icon(Icons.person)),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          final seleccionados = usuarios
              .where((u) => _selectedUserIds.contains(u.id))
              .toList();
          if (widget.maxSeleccion == 1) {
            // Modo chat: crear o reutilizar chat y navegar
            if (seleccionados.isNotEmpty) {
              // Debes obtener el currentUser (puedes pasarlo por constructor o Provider)
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final currentUser = userProvider.usuarios.firstWhere((u) => u.id == widget.currentUserId);
              final otroUsuario = seleccionados.first;
              final chat = await crearChatConUsuario(currentUser, otroUsuario);
              if (chat != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatId: chat.id),
                  ),
                );
              }
            }
          } else {
            // Modo grupo: usa el callback
            widget.onSelectionConfirmed(seleccionados);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
