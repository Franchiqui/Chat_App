// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseConfig.pb;
    final baseUrl = pb.baseUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context, baseUrl),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.fechaMensaje,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (isMe)
                      Icon(
                        message.visto ? Icons.done_all : Icons.done,
                        size: 14,
                        color: Colors.white70,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, String baseUrl) {
  switch (message.tipo) {
    case MessageType.imagen:
      String? imageUrl;
      if (message.imagenUrl != null && message.imagenUrl!.isNotEmpty) {
        imageUrl = message.imagenUrl;
      } else if (message.filePath != null) {
        // Construir URL usando el ID de mensaje y el path del archivo
        imageUrl = '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          if (message.texto.isNotEmpty && message.texto != 'Imagen')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message.texto,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      );
      
      case MessageType.audio:
      case MessageType.audioVoz:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade800 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: isMe ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Audio',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (message.texto.isNotEmpty && message.texto != 'Audio')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  message.texto,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        );
      
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            if (message.texto.isNotEmpty && message.texto != 'Video')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  message.texto,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        );
      
      case MessageType.documento:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade800 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.fileName ?? 'Documento',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (message.texto.isNotEmpty && !message.texto.startsWith('Documento:'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  message.texto,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        );
      
      case MessageType.texto:
    default:
      return Text(
        message.texto,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
        ),
      );
  }
}
}
