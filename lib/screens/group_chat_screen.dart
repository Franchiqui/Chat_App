// lib/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/message_model.dart';
import '../widgets/image_fullscreen_dialog.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PocketBase pb = PocketBaseConfig.pb;
  bool _isRecording = false;
  bool _isAttaching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _subscribeToMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    await Provider.of<GroupProvider>(context, listen: false)
        .getGroupMessages(widget.groupId);
    _scrollToBottom();
  }

  void _subscribeToMessages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null || !authProvider.isAuthenticated) {
      // No suscribirse si no hay usuario autenticado
      return;
    }
    pb.collection(PocketBaseConfig.groupMessagesCollection).subscribe('*', (e) {
      if (e.action != 'create') return;
      final data = e.record!.toJson();
      if (data['grupo'] == widget.groupId ||
          data['grupoId'] == widget.groupId) {
        Provider.of<GroupProvider>(context, listen: false)
            .addGroupMessage(data);
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) return;

    _messageController.clear();

    await groupProvider.sendGroupMessage(
      groupId: widget.groupId,
      currentUserId: authProvider.user!.id,
      text: text,
    );
  }

  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await groupProvider.sendGroupMessage(
          groupId: widget.groupId,
          currentUserId: authProvider.user!.id,
          text: 'Imagen',
          file: bytes,
          tipo: MessageType.imagen,
        );
      } else {
        final file = File(image.path);
        await groupProvider.sendGroupMessage(
          groupId: widget.groupId,
          currentUserId: authProvider.user!.id,
          text: 'Imagen',
          file: file,
          tipo: MessageType.imagen,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final fileName = result.files.single.name;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = lookupMimeType(fileName);

      MessageType tipo;
      String messageText;

      // Soporte para imágenes
      if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(extension)) {
        tipo = MessageType.imagen;
        messageText = 'Imagen';
      }
      // Soporte para videos
      else if (["mp4", "mov", "avi", "flv", "wmv", "mkv"].contains(extension)) {
        tipo = MessageType.video;
        messageText = 'Video';
      }
      // Soporte para audios
      else if (["mp3", "wav", "m4a", "aac", "ogg"].contains(extension)) {
        tipo = MessageType.audio;
        messageText = 'Audio';
      }
      // Soporte para documentos permitidos
      else if (["pdf", "txt", "html", "php"].contains(extension)) {
        const allowedMimeTypes = [
          'application/pdf',
          'text/plain',
          'text/html',
          'text/x-php',
        ];
        if (mimeType != null && allowedMimeTypes.contains(mimeType)) {
          tipo = MessageType.documento;
          messageText = 'Documento: $fileName';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Tipo de documento no permitido. Solo PDF, TXT, HTML o PHP.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de archivo no soportado.')),
        );
        return;
      }

      if (kIsWeb) {
        final Uint8List? fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo leer el archivo.')),
          );
          return;
        }
        await groupProvider.sendGroupMessage(
          groupId: widget.groupId,
          currentUserId: authProvider.user!.id,
          text: messageText,
          file: fileBytes,
          tipo: tipo,
        );
      } else {
        File file = File(result.files.single.path!);
        await groupProvider.sendGroupMessage(
          groupId: widget.groupId,
          currentUserId: authProvider.user!.id,
          text: messageText,
          file: file,
          tipo: tipo,
        );
      }
    }
  }

  void _showAttachmentOptions() {
    setState(() {
      _isAttaching = !_isAttaching;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);

    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return const Scaffold(
          body: Center(child: Text('No has iniciado sesión')));
    }

    final group = groupProvider.getGroupById(widget.groupId);
    if (group == null) {
      return const Scaffold(body: Center(child: Text('Grupo no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                group.nombreGrupo.isNotEmpty
                    ? group.nombreGrupo[0].toUpperCase()
                    : 'G',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(group.nombreGrupo),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              // Mostrar miembros del grupo
              _showGroupMembers(group);
            },
          ),
          // lib/screens/group_chat_screen.dart (continuación)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: groupProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupProvider.groupMessages.isEmpty
                    ? const Center(child: Text('No hay mensajes aún'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10.0),
                        itemCount: groupProvider.groupMessages.length,
                        itemBuilder: (context, index) {
                          final message = groupProvider.groupMessages[index];
                          final isMe = message['user'] == authProvider.user!.id;

                          return _buildGroupMessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          if (_isAttaching)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isAttaching ? Icons.close : Icons.add,
                      color: Colors.blue,
                    ),
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          
        ],
      ),
    );
  }

  Widget _buildGroupMessageBubble({
    required Map<String, dynamic> message,
    required bool isMe,
  }) {
    final pb = PocketBaseConfig.pb;
    final baseUrl = pb.baseUrl;
    final String senderName =
        message['expand']?['user']?['displayName_A'] ?? 'Usuario';
    final String texto = message['texto'] ?? '';
    final String? tipo = message['tipo'];
    final String? filePath = message['filePath'];
    final String? imagenUrl = message['imagenUrl'];
    final DateTime createdAt = DateTime.parse(message['created']);
    final String timeString = '${createdAt.hour}:${createdAt.minute}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 15,
                child: Text(senderName[0].toUpperCase()),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (tipo == 'texto' ? 0.7 : 0.5),
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                _buildGroupMessageContent(
                    tipo, texto, filePath, imagenUrl, baseUrl, isMe),
                const SizedBox(height: 5),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMessageContent(
    String? tipo,
    String texto,
    String? filePath,
    String? imagenUrl,
    String baseUrl,
    bool isMe,
  ) {
    switch (tipo) {
      case 'documento':
        final fileName = filePath?.split('/')?.last ?? 'Documento';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (texto.isNotEmpty && !texto.startsWith('Documento:'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  texto,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        );

      case 'texto':
      case 'video':
        return Text(
          texto,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Function onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: isActive ? Colors.red : Colors.blue,
            radius: 25,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showGroupMembers(final group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Miembros del grupo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: group.miembros.length,
                  itemBuilder: (context, index) {
                    final memberId = group.miembros[index];
                    // Aquí deberías obtener los detalles del usuario con este ID
                    // Por ahora, mostramos el ID como ejemplo
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text('Usuario $memberId'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
