// lib/screens/group_chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../models/message_model.dart';

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
    pb.collection(PocketBaseConfig.groupMessagesCollection).subscribe('*', (e) {
      if (e.action != 'create') return;
      
      final data = e.record!.toJson();
      if (data['grupo'] == widget.groupId || data['grupoId'] == widget.groupId) {
        Provider.of<GroupProvider>(context, listen: false).addGroupMessage(data);
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

  Future<void> _pickFile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final extension = fileName.split('.').last.toLowerCase();

      MessageType tipo;
      String messageText;

      if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension)) {
        tipo = MessageType.audio;
        messageText = 'Audio';
      } else if (['mp4', 'mov', 'avi', 'flv', 'wmv'].contains(extension)) {
        tipo = MessageType.video;
        messageText = 'Video';
      } else {
        tipo = MessageType.documento;
        messageText = 'Documento: $fileName';
      }

      await groupProvider.sendGroupMessage(
        groupId: widget.groupId,
        currentUserId: authProvider.user!.id,
        text: messageText,
        file: file,
        tipo: tipo,
      );
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
      return const Scaffold(body: Center(child: Text('No has iniciado sesión')));
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
                group.nombreGrupo.isNotEmpty ? group.nombreGrupo[0].toUpperCase() : 'G',
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
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.image,
                    label: 'Imagen',
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.mic,
                    label: 'Audio',
                    onTap: () {
                      // Implementar grabación de audio
                      setState(() {
                        _isRecording = !_isRecording;
                      });
                    },
                    isActive: _isRecording,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'Archivo',
                    onTap: _pickFile,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
    final String senderName = message['expand']?['user']?['displayName_A'] ?? 'Usuario';
    final String texto = message['texto'] ?? '';
    final String? tipo = message['tipo'];
    final String? filePath = message['filePath'];
    final String? imagenUrl = message['imagenUrl'];
    final DateTime createdAt = DateTime.parse(message['created']);
    final String timeString = '${createdAt.hour}:${createdAt.minute}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                _buildGroupMessageContent(tipo, texto, filePath, imagenUrl, baseUrl, isMe),
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
      case 'imagen':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagenUrl != null && imagenUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imagenUrl,
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
                ),
              )
            else if (filePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  '$baseUrl/api/files/${PocketBaseConfig.groupMessagesCollection}/${filePath}',
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
                ),
              ),
            if (texto.isNotEmpty && texto != 'Imagen')
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
      
      case 'audio':
      case 'audioVoz':
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
            if (texto.isNotEmpty && texto != 'Audio')
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
      
      case 'video':
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
            if (texto.isNotEmpty && texto != 'Video')
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
      
      case 'documento':
        final fileName = texto.startsWith('Documento: ')
            ? texto.substring(11)
            : 'Documento';
        
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
                      fileName,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
      default:
        return Text(
          texto,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        );
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
