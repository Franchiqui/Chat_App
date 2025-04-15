// lib/widgets/chat_list_item.dart
import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final Function onTap;

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar si el usuario actual es user1 o user2
    final bool isUser1 = chat.user1 == currentUserId;
    final String displayName = isUser1 ? chat.displayNameB : chat.displayNameA;
    final String? avatarUrl = isUser1 ? chat.fotoUrlB : chat.fotoUrlA;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: chat.ultimoMensaje != null && chat.ultimoMensaje!.isNotEmpty
          ? Text(
              chat.ultimoMensaje!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('No hay mensajes aún'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.fechaChat ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            chat.horaChat ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      onTap: () => onTap(),
    );
  }
}
