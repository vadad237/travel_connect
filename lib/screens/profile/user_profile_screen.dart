import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agent_provider.dart';
import 'edit_profile_screen.dart';
import 'agent_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
  }

  Future<void> _loadAgentProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.role == 'agent') {
      await agentProvider.loadCurrentAgentProfile(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AgentProvider>(
      builder: (context, authProvider, agentProvider, child) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAgent = user.role == 'agent';
        final agentProfile = agentProvider.currentAgentProfile;

        // Use agent business name if available, otherwise use user display name
        final displayName = (isAgent && agentProfile != null)
            ? agentProfile.businessName
            : user.displayName;
        
        // Always use user's photoUrl from their account
        final photoUrl = user.photoUrl;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  isAgent ? 'Travel Agent' : 'Traveler',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 32),
              if (isAgent) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ).then((_) => _loadAgentProfile()); // Reload after editing
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View My Agent Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    if (agentProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgentProfileScreen(agentId: agentProfile.id),
                        ),
                      );
                    } else {
                      final agent = await agentProvider.getAgentByUserId(user.id);
                      if (agent != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AgentProfileScreen(agentId: agent.id),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'TravelConnect',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 TravelConnect',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    agentProvider.clearCurrentAgentProfile();
                    await authProvider.signOut();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}