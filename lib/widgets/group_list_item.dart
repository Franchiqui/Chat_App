// lib/widgets/group_list_item.dart
import 'package:flutter/material.dart';
import '../models/group_model.dart';

class GroupListItem extends StatelessWidget {
  final GroupModel group;
  final Function onTap;

  const GroupListItem({
    Key? key,
    required this.group,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          group.nombreGrupo.isNotEmpty ? group.nombreGrupo[0].toUpperCase() : 'G',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        group.nombreGrupo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: group.ultimoMensaje != null && group.ultimoMensaje!.isNotEmpty
          ? Text(
              group.ultimoMensaje!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('No hay mensajes aún'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            group.fechaChat ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            group.horaChat ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      onTap: () => onTap(),
    );
  }
}
