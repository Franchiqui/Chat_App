// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await chatProvider.getUserChats(authProvider.user!.id);
      await groupProvider.getUserGroups(authProvider.user!.id);
    }

    setState(() {
      _isLoading = false;
    });
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
              // Aquí puedes implementar la lógica para buscar usuarios
              // y comenzar un nuevo chat
              _showUserSearchDialog();
            },
            heroTag: 'createChat',
            child: const Icon(Icons.chat),
          ),
        ],
      ),
    );
  }

  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Buscar usuario'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario',
              hintText: 'Ingresa el nombre de usuario',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí implementarías la búsqueda de usuarios
                // y la creación de un nuevo chat
                Navigator.of(context).pop();
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }
}
