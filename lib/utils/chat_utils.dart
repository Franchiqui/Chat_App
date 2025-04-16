import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';

/// Busca un chat existente entre los dos usuarios o lo crea si no existe y retorna el ChatModel.
Future<ChatModel?> crearChatConUsuario(UserModel currentUser, UserModel otroUsuario) async {
  final chatService = ChatService();
  // 1. Buscar si ya existe un chat entre los dos usuarios
  final chatExistente = await chatService.findChatBetweenUsers(currentUser.id, otroUsuario.id);
  if (chatExistente != null) {
    return chatExistente;
  }
  // 2. Crear el chat si no existe
  final nuevoChat = await chatService.createChat(currentUser, otroUsuario);
  return nuevoChat;
}
