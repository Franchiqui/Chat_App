// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PocketBase pb = PocketBaseConfig.pb;

  bool _isAttaching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _subscribeToMessages(); // Suscribirse a cambios en tiempo real
      // Scroll automático al último mensaje después de cargar mensajes
      Future.delayed(const Duration(milliseconds: 400), _scrollToBottom);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Cancelar la suscripción al cerrar el chat
    pb.collection('messages').unsubscribe('*');
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      print('Cargando mensajes para el chat: ${widget.chatId}'); // Depuración

      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      await messageProvider.getChatMessages(widget.chatId);

      // Marcar como vistos todos los mensajes recibidos no vistos
      if (currentUserId != null) {
        for (final msg in messageProvider.messages) {
          print('[VISTO][LOAD] Mensaje: id=${msg.id}, userId=${msg.userId}, currentUserId=$currentUserId, visto=${msg.visto}');
          if ((msg.userId ?? '').isNotEmpty && msg.userId != currentUserId && !msg.visto) {
            print('[VISTO][LOAD] Marcando como visto: ${msg.id}');
            await messageProvider.markMessageAsRead(msg.id);
          }
        }
        // Forzar refresco de mensajes tras marcar como visto
        await messageProvider.getChatMessages(widget.chatId);
      }

      print('Mensajes cargados: ${messageProvider.messages.length}'); // Depuración

      _scrollToBottom();
    } catch (e) {
      print('Error al cargar mensajes: $e'); // Depuración
    }
  }

  void _subscribeToMessages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null || !authProvider.isAuthenticated) {
      // No suscribirse si no hay usuario autenticado
      return;
    }
    pb.collection(PocketBaseConfig.messagesCollection).subscribe('*', (e) async {
      if (e.action != 'create') return;
      final message = MessageModel.fromJson(e.record!.toJson());
      if (message.idChat == widget.chatId) {
        final currentUserId = authProvider.user!.id;
        // Si el mensaje es recibido y no está visto, márcalo como visto
        print('[VISTO][REALTIME] Mensaje: id=${message.id}, userId=${message.userId}, currentUserId=$currentUserId, visto=${message.visto}');
        if ((message.userId ?? '').isNotEmpty && message.userId != currentUserId && !message.visto) {
          print('[VISTO][REALTIME] Marcando como visto: ${message.id}');
          await Provider.of<MessageProvider>(context, listen: false).markMessageAsRead(message.id);
          // Forzar refresco de mensajes tras marcar como visto
          await Provider.of<MessageProvider>(context, listen: false).getChatMessages(widget.chatId);
        }
        Provider.of<MessageProvider>(context, listen: false)
            .addMessage(message);

        // Actualizar el último mensaje en la lista de chats
        if (message.texto.isNotEmpty) {
          Provider.of<ChatProvider>(context, listen: false)
              .updateLastMessage(widget.chatId, message.texto);
        }

        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
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
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    final chat = chatProvider.getChatById(widget.chatId);
    if (chat == null || authProvider.user == null) return;

    final currentUserId = authProvider.user!.id;
    final otherUserId = chat.user1 == currentUserId ? chat.user2 : chat.user1;

    _messageController.clear();

    await messageProvider.sendTextMessage(
      widget.chatId,
      currentUserId,
      otherUserId,
      text,
    );

    await chatProvider.updateLastMessage(widget.chatId, text);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    final chat = chatProvider.getChatById(widget.chatId);
    if (chat == null || authProvider.user == null) return;

    final currentUserId = authProvider.user!.id;
    final otherUserId = chat.user1 == currentUserId ? chat.user2 : chat.user1;

    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final Uint8List fileBytes = result.files.single.bytes!;
        final String fileName = result.files.single.name;
        await messageProvider.sendFileMessage(
          chatId: widget.chatId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          file: fileBytes,
          fileName: fileName,
          tipo: MessageType.imagen,
          text: 'Imagen',
          context: context,
        );
        await chatProvider.updateLastMessage(widget.chatId, 'Imagen');
        _scrollToBottom();
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final fileName = image.name;
        await messageProvider.sendFileMessage(
          chatId: widget.chatId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          file: file,
          fileName: fileName,
          tipo: MessageType.imagen,
          text: 'Imagen',
          context: context,
        );
        await chatProvider.updateLastMessage(widget.chatId, 'Imagen');
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickFile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    final chat = chatProvider.getChatById(widget.chatId);
    if (chat == null || authProvider.user == null) return;

    final currentUserId = authProvider.user!.id;
    final otherUserId = chat.user1 == currentUserId ? chat.user2 : chat.user1;

    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
      );
      if (result == null) return;
      final fileName = result.files.single.name;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = lookupMimeType(fileName);
      MessageType tipo;
      String messageText;

      // Soporte para imágenes
      if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(extension)) {
        tipo = MessageType.imagen;
        messageText = 'Imagen';
      } else if (["mp4", "mov", "avi", "flv", "wmv", "mkv"].contains(extension)) {
        tipo = MessageType.video;
        messageText = 'Video';
      } else if (["mp3", "wav", "m4a", "aac", "ogg"].contains(extension)) {
        tipo = MessageType.audio;
        messageText = 'Audio';
      } else if (["pdf", "txt", "html", "php"].contains(extension)) {
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
            const SnackBar(content: Text('Solo se permiten documentos PDF, TXT, HTML o PHP.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de archivo no soportado.')),
        );
        return;
      }

      final Uint8List? fileBytes = result.files.single.bytes;
      if (fileBytes == null || fileName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo o el nombre es inválido.')),
        );
        return;
      }
      await messageProvider.sendFileMessage(
        chatId: widget.chatId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        file: fileBytes,
        fileName: fileName,
        tipo: tipo,
        text: messageText,
        context: context,
      );
      await chatProvider.updateLastMessage(widget.chatId, messageText);
      _scrollToBottom();
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      final fileName = result.files.single.name;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = lookupMimeType(fileName);
      MessageType tipo;
      String messageText;

      // Soporte para imágenes
      if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(extension)) {
        tipo = MessageType.imagen;
        messageText = 'Imagen';
      } else if (["mp4", "mov", "avi", "flv", "wmv", "mkv"].contains(extension)) {
        tipo = MessageType.video;
        messageText = 'Video';
      } else if (["mp3", "wav", "m4a", "aac", "ogg"].contains(extension)) {
        tipo = MessageType.audio;
        messageText = 'Audio';
      } else if (["pdf", "txt", "html", "php"].contains(extension)) {
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
            const SnackBar(content: Text('Solo se permiten documentos PDF, TXT, HTML o PHP.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de archivo no soportado.')),
        );
        return;
      }

      final String? filePath = result.files.single.path;
      if (filePath != null && filePath.isNotEmpty && fileName.isNotEmpty) {
        final file = File(filePath);
        await messageProvider.sendFileMessage(
          chatId: widget.chatId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          file: file,
          fileName: fileName,
          tipo: tipo,
          text: messageText,
          context: context,
        );
        await chatProvider.updateLastMessage(widget.chatId, messageText);
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo o el nombre es inválido.')),
        );
        return;
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
    final chatProvider = Provider.of<ChatProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);

    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return const Scaffold(
          body: Center(child: Text('No has iniciado sesión')));
    }

    final chat = chatProvider.getChatById(widget.chatId);
    if (chat == null) {
      return const Scaffold(body: Center(child: Text('Chat no encontrado')));
    }

    final currentUserId = authProvider.user!.id;
    final isUser1 = chat.user1 == currentUserId;
    final displayName = isUser1 ? chat.displayNameB : chat.displayNameA;
    final rawAvatarUrl = isUser1 ? chat.fotoUrlB : chat.fotoUrlA;
    final pb = PocketBaseConfig.pb;
    final baseUrl = pb.baseUrl;
    String? avatarUrl;
    if (rawAvatarUrl != null && rawAvatarUrl.isNotEmpty) {
      if (rawAvatarUrl.startsWith('http')) {
        avatarUrl = rawAvatarUrl;
      } else {
        final otherUserId = isUser1 ? chat.user2 : chat.user1;
        avatarUrl = '$baseUrl/api/files/users/$otherUserId/$rawAvatarUrl';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 8),
            Text(displayName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messageProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messageProvider.messages.isEmpty
                    ? const Center(child: Text('No hay mensajes aún'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10.0),
                        itemCount: messageProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = messageProvider.messages[index];
                          final isMe = message.user1 == currentUserId;

                          // Depuración
                          print(
                              'Renderizando mensaje: ${message.texto} - Tipo: ${message.tipo}');

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            onLongPress: () {
                              // Opciones al mantener presionado
                            },
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.image,
                    label: 'Imagen',
                    onTap: _pickImage,
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
}
