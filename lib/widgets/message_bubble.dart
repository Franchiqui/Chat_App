// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';
import 'audio_player_widget.dart';
import 'video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';

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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
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
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    // Intentar obtener el avatar del usuario remitente
    String? avatar = message.senderAvatar;
    // Si tienes el avatar en el modelo de mensaje, úsalo. Si no, usa un placeholder.
    // Aquí puedes modificar para obtener el avatar real desde el modelo de mensaje si lo tienes.
    // Ejemplo si tienes message.avatar:
    // String? avatarUrl = message.avatar;
    // Por ahora, avatarUrl será null y saldrá el placeholder.
    return CircleAvatar(
      radius: 18,
      backgroundImage:
          (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
      child:
          (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null,
    );
  }

  Widget _buildMessageContent(BuildContext context, String baseUrl) {
    switch (message.tipo) {
      case MessageType.audioVoz:
        // Usa el campo mp3Url o filePath para construir la URL
        String? audioUrl = message.mp3Url;
        if ((audioUrl == null || audioUrl.isEmpty) && message.filePath != null) {
          audioUrl = '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          return AudioPlayerWidget(audioUrl: audioUrl);
        } else {
          return const Text('Audio no disponible');
        }

      case MessageType.imagen:
        String? imageUrl;
        if (message.imagenUrl != null && message.imagenUrl!.isNotEmpty) {
          imageUrl = message.imagenUrl;
        } else if (message.filePath != null) {
          // Construir URL usando el ID de mensaje y el path del archivo
          imageUrl =
              '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
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
        String? audioUrl = message.mp3Url;
        if ((audioUrl == null || audioUrl.isEmpty) && message.filePath != null) {
          audioUrl = '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AudioPlayerWidget(audioUrl: audioUrl, fileName: message.fileName),
              if (message.texto.isNotEmpty && message.texto != 'Audio' && message.texto != 'audioVoz')
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
        } else {
          return const Text('Audio no disponible');
        }

      case MessageType.video:
        String? videoUrl;
        if (message.videoUrl != null && message.videoUrl!.isNotEmpty) {
          videoUrl = message.videoUrl;
        } else if (message.filePath != null) {
          videoUrl =
              '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (videoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: VideoPlayerWidget(videoUrl: videoUrl, fileName: message.fileName),
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
        String? docUrl;
        if (message.documentUrl != null && message.documentUrl!.isNotEmpty) {
          docUrl = message.documentUrl;
        } else if (message.filePath != null) {
          docUrl =
              '$baseUrl/api/files/${PocketBaseConfig.messagesCollection}/${message.id}/${message.filePath}';
        }
        // Detectar si es un archivo de audio por extensión
        final audioExtensions = ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'amr'];
        final isAudio = message.fileName != null &&
            audioExtensions.contains(message.fileName!.split('.').last.toLowerCase());
        if (isAudio && docUrl != null) {
          // Mostrar reproductor de audio en vez de solo icono
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AudioPlayerWidget(audioUrl: docUrl, fileName: message.fileName),
              if (message.texto.isNotEmpty &&
                  !message.texto.startsWith('Documento:'))
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
        }
        // Si no es audio, mostrar como documento normal
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: docUrl != null
                  ? () async {
                      final uri = Uri.parse(docUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue.shade800 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFileIcon(message.fileName ?? 'Documento'),
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
                    if (docUrl != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Icon(Icons.open_in_new, color: Colors.white, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            if (message.texto.isNotEmpty &&
                !message.texto.startsWith('Documento:'))
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

  // Icono según extensión de archivo
  Widget _buildFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    final icons = {
      'pdf': Icons.picture_as_pdf,
      'doc': Icons.article, // Documento Word
      'docx': Icons.article,
      'xls': Icons.grid_on, // Excel
      'xlsx': Icons.grid_on,
      'ppt': Icons.slideshow, // PowerPoint
      'pptx': Icons.slideshow,
      'txt': Icons.notes, // Texto
      'zip': Icons.archive, // Comprimido
      'rar': Icons.archive,
      'csv': Icons.table_rows,
      'json': Icons.data_object,
      'xml': Icons.code,
      'apk': Icons.android,
      'exe': Icons.computer,
      'mp3': Icons.music_note,
      'wav': Icons.music_note,
      'mp4': Icons.movie,
      'avi': Icons.movie,
      'mov': Icons.movie,
      'jpg': Icons.image,
      'jpeg': Icons.image,
      'png': Icons.image,
      'gif': Icons.gif,
    };
    return Icon(
      icons[ext] ?? Icons.insert_drive_file,
      color: _getFileIconColor(ext),
      size: 28,
    );
  }

  // Color del icono según extensión
  Color _getFileIconColor(String extension) {
    final colors = {
      'pdf': Colors.red,
      'doc': Colors.indigo,
      'docx': Colors.indigo,
      'xls': Colors.green,
      'xlsx': Colors.green,
      'ppt': Colors.deepOrange,
      'pptx': Colors.deepOrange,
      'txt': Colors.deepPurple,
      'zip': Colors.brown,
      'rar': Colors.brown,
      'csv': Colors.teal,
      'json': Colors.blueGrey,
      'xml': Colors.blueGrey,
      'apk': Colors.lightGreen,
      'exe': Colors.black,
      'mp3': Colors.pink,
      'wav': Colors.pink,
      'mp4': Colors.deepPurpleAccent,
      'avi': Colors.deepPurpleAccent,
      'mov': Colors.deepPurpleAccent,
      'jpg': Colors.orange,
      'jpeg': Colors.orange,
      'png': Colors.lightBlue,
      'gif': Colors.amber,
    };
    return colors[extension] ?? Colors.grey;
  }
}

