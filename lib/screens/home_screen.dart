// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/group_list_item.dart';
import 'auth/login_screen.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    // Declara los providers correctamente
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await chatProvider.getUserChats(authProvider.user!.id);
      await groupProvider.getUserGroups(authProvider.user!.id);
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _refresh() async {
    await _loadData();
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Grupos'),
          ],
        ),
      ),
      body: _isLoading || authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab de Chats Individuales
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: chatProvider.chats.isEmpty
                      ? const Center(child: Text('No hay chats disponibles'))
                      : ListView.builder(
                          itemCount: chatProvider.chats.length,
                          itemBuilder: (context, index) {
                            final chat = chatProvider.chats[index];
                            return ChatListItem(
                              chat: chat,
                              currentUserId: authProvider.user!.id,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(chatId: chat.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),

                // Tab de Grupos
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: groupProvider.groups.isEmpty
                      ? const Center(child: Text('No hay grupos disponibles'))
                      : ListView.builder(
                          itemCount: groupProvider.groups.length,
                          itemBuilder: (context, index) {
                            final group = groupProvider.groups[index];
                            return GroupListItem(
                              group: group,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GroupChatScreen(groupId: group.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_tabController.index == 1)
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              heroTag: 'createGroup',
              child: const Icon(Icons.group_add),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
           _showUserSearchDialog(context);
            },
            heroTag: 'createChat',
            child: const Icon(Icons.chat),
          ),
        ],
      ),
    );
  }

  void _showUserSearchDialog(BuildContext context) {
  final TextEditingController searchController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) {
      List<Map<String, dynamic>> searchResults = [];
      bool isLoading = true; // Inicialmente cargando
      
      return StatefulBuilder(
        builder: (context, setState) {
          // Cargar todos los usuarios al abrir el diálogo
          if (isLoading) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.searchUsers('').then((users) {
              setState(() {
                searchResults = users;
                isLoading = false;
              });
            });
          }
          
          return AlertDialog(
            title: const Text('Seleccionar usuario'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar usuario',
                      hintText: 'Ingresa el nombre de usuario',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) async {
                      setState(() {
                        isLoading = true;
                      });
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final results = await authProvider.searchUsers(query);
                      setState(() {
                        searchResults = results;
                        isLoading = false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No se encontraron usuarios'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                                  ? NetworkImage(user['avatar'])
                                  : null,
                              child: user['avatar'] == null || user['avatar'].toString().isEmpty
                                  ? Text(user['displayName'][0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user['displayName']),
                            subtitle: Text(user['username']),
                            onTap: () async {
                              Navigator.of(context).pop(); // Cerrar el diálogo
                              await _createChatWithUser(user); // Crear o navegar al chat
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    },
  );
}
Future<void> _createChatWithUser(Map<String, dynamic> user) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

  if (authProvider.user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No has iniciado sesión')),
    );
    return;
  }

  final currentUserId = authProvider.user!.id;
  final otherUserId = user['id'];
  final currentDisplayName = authProvider.user!.displayName_A;
  final otherDisplayName = user['displayName'];

  final currentUser = UserModel(
    id: currentUserId,
    username: authProvider.user!.username,
    displayName_A: currentDisplayName,
    avatar: authProvider.user!.avatar,
  );

  final otherUser = UserModel(
    id: otherUserId,
    username: user['username'] ?? '', // <-- Valor predeterminado
    displayName_A: user['displayName_A'] ?? 'Usuario sin nombre', // <-- Valor predeterminado
    avatar: user['avatar'], // Este campo puede ser null
  );

  final newChat = await chatProvider.createChat(currentUser, otherUser);

  if (mounted) { // Verificar antes de navegar
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: newChat.id),
      ),
    );
  }
}
}