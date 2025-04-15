// lib/config/pocketbase_config.dart
import 'package:pocketbase/pocketbase.dart';

class PocketBaseConfig {
  static final PocketBase pb = PocketBase('https://pocketbase-chat.fly.dev');
  
  // Colecciones
  static const String usersCollection = '_pb_users_auth_';
  static const String chatsCollection = 'CHAT';
  static const String messagesCollection = 'mensajes';
  static const String groupsCollection = 'grupos';
  static const String groupMessagesCollection = 'group_messages';
  static const String notificationsCollection = 'notificaciones';
}
