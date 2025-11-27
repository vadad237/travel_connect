import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agent_provider.dart';
import '../../models/travel_agent_model.dart';
import '../home/agent_catalogue_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isInitialSetup;

  const EditProfileScreen({Key? key, this.isInitialSetup = false})
      : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _profilePhotoUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      // Use user's Google/Auth photo
      _profilePhotoUrl = authProvider.currentUser!.photoUrl;
      
      if (!widget.isInitialSetup) {
        final agent = await agentProvider.getAgentByUserId(authProvider.currentUser!.id);
        if (agent != null) {
          setState(() {
            _businessNameController.text = agent.businessName;
            _descriptionController.text = agent.description;
            _locationController.text = agent.location;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use user's auth photo URL
      final photoUrl = currentUser.photoUrl;

      if (widget.isInitialSetup) {
        // Create new agent profile
        final agent = TravelAgentModel(
          id: '',
          userId: currentUser.id,
          businessName: _businessNameController.text.trim(),
          description: _descriptionController.text.trim(),
          profilePhoto: photoUrl,
          location: _locationController.text.trim(),
          createdAt: DateTime.now(),
        );

        await agentProvider.createAgent(agent);
        
        // Reload the agent profile after creation
        await agentProvider.loadCurrentAgentProfile(currentUser.id);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AgentCatalogueScreen()),
          );
        }
      } else {
        // Update existing agent profile
        final agent = await agentProvider.getAgentByUserId(currentUser.id);
        if (agent != null) {
          await agentProvider.updateAgent(agent.id, {
            'businessName': _businessNameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'profilePhoto': photoUrl,
            'location': _locationController.text.trim(),
          });

          // Reload the agent profile after update
          await agentProvider.loadCurrentAgentProfile(currentUser.id);

          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        }
      }
    } catch (e) {
      print('🔴 Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Setup Profile' : 'Edit Profile'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _profilePhotoUrl.isNotEmpty
                              ? NetworkImage(_profilePhotoUrl)
                              : const AssetImage('assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Photo from your Google account',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 50) {
                            return 'Description must be at least 50 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.isInitialSetup ? 'Create Profile' : 'Save Changes',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}