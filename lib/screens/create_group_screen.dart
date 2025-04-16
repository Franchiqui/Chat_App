// lib/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<String> _selectedUsers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // En lib/screens/create_group_screen.dart

Future<void> _searchUsers(String query) async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final results = await authProvider.searchUsers(query);
    
    if (!mounted) return;
    
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _searchResults = [];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al buscar usuarios: ${e.toString()}')),
    );
  }
}


  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate() && _selectedUsers.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        
        if (authProvider.user == null) return;

        final group = await groupProvider.createGroup(
          authProvider.user!.id,
          _groupNameController.text.trim(),
          _selectedUsers,
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(groupId: group.id),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un usuario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre para el grupo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Miembros del grupo:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar usuarios',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _searchUsers,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (_searchResults.isEmpty) {
                      return Center(child: Text('No se encontraron usuarios'));
                    }

                    return ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          title: Text(user['displayName'] ?? user['username']),
                          subtitle: Text('@${user['username']}'),
                          onTap: () => _toggleUserSelection(user['id']),
                          // Mostrar un check si el usuario está seleccionado
                          trailing: _selectedUsers.contains(user['id']) 
                              ? Icon(Icons.check, color: Colors.blue) 
                              : null,
                        );
                      },
                    );
                  }
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Grupo',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
