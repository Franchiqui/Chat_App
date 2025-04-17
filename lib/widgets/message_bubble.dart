// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../config/pocketbase_config.dart';
import '../models/message_model.dart';
import 'audio_player_widget.dart';
import 'video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'image_fullscreen_dialog.dart';

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
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (message.tipo == MessageType.texto ? 0.7 : 0.5),
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
      case MessageType.audioVoz:
        String? audioUrl = message.audioUrl;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          return AudioPlayerWidget(audioUrl: audioUrl);
        } else {
          return const Text('Audio no disponible');
        }

      case MessageType.texto:
        return Text(
          message.texto,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        );

      case MessageType.video:
        String? videoUrl = message.videoUrl;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          return VideoPlayerWidget(videoUrl: videoUrl, fileName: message.fileName);
        } else {
          return const Text('Video no disponible');
        }

      case MessageType.documento:
        String? documentUrl = message.documentUrl;
        return Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFileIcon(message.fileName ?? 'documento'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Documento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        fontSize: 15,
                        decoration: documentUrl != null && documentUrl.isNotEmpty
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (documentUrl != null && documentUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          if (await canLaunchUrl(Uri.parse(documentUrl))) {
                            await launchUrl(Uri.parse(documentUrl), mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.open_in_new, color: Colors.blue, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Abrir',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      
    

      case MessageType.imagen:
        String? imageUrl = message.imageUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => ImageFullscreenDialog(
                        imageUrl: imageUrl,
                        heroTag: imageUrl,
                      ),
                    );
                  },
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 220,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.broken_image, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text('Imagen no disponible',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      );
                    },
                  ),
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
        String? audioUrl = message.audioUrl;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          return AudioPlayerWidget(audioUrl: audioUrl, fileName: message.fileName);
        } else {
          return const Text('Audio no disponible');
        }

      case MessageType.texto:
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
