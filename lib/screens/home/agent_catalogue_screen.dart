import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../profile/agent_profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/user_profile_screen.dart';

class AgentCatalogueScreen extends StatefulWidget {
  const AgentCatalogueScreen({Key? key}) : super(key: key);

  @override
  State<AgentCatalogueScreen> createState() => _AgentCatalogueScreenState();
}

class _AgentCatalogueScreenState extends State<AgentCatalogueScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      agentProvider.listenToAgents();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        chatProvider.listenToUserChats(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> get _screens => [
        _buildCatalogueView(),
        const ChatListScreen(),
        const UserProfileScreen(),
      ];

  Widget _buildCatalogueView() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search travel agents...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                          Provider.of<AgentProvider>(context, listen: false)
                              .searchAgents('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {});
                Provider.of<AgentProvider>(context, listen: false)
                    .searchAgents(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<AgentProvider>(
              builder: (context, agentProvider, child) {
                if (agentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (agentProvider.agents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.travel_explore,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No travel agents found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                              agentProvider.searchAgents('');
                              FocusScope.of(context).unfocus();
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    agentProvider.listenToAgents();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: agentProvider.agents.length,
                    itemBuilder: (context, index) {
                      final agent = agentProvider.agents[index];
                      return _AgentCardWithReviews(
                        agent: agent,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgentProfileScreen(agentId: agent.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Agents'),
        centerTitle: true,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUserId = authProvider.currentUser?.id ?? '';
              
              final unreadCount = chatProvider.chats
                  .where((chat) => (chat.unreadCount[currentUserId] ?? 0) > 0)
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.currentUser?.id ?? '';
          
          final unreadCount = chatProvider.chats
              .where((chat) => (chat.unreadCount[currentUserId] ?? 0) > 0)
              .length;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: unreadCount > 0
                    ? Badge( 
                        label: Text('$unreadCount'),
                        child: const Icon(Icons.chat),
                      )
                    : const Icon(Icons.chat),
                label: 'Chats',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AgentCardWithReviews extends StatefulWidget {
  final dynamic agent;
  final VoidCallback onTap;

  const _AgentCardWithReviews({
    required this.agent,
    required this.onTap,
  });

  @override
  State<_AgentCardWithReviews> createState() => _AgentCardWithReviewsState();
}

class _AgentCardWithReviewsState extends State<_AgentCardWithReviews> {
  String _userPhotoUrl = '';
  bool _isLoadingPhoto = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agent.userId)
          .get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        setState(() {
          _userPhotoUrl = userData?['photoUrl'] as String? ?? '';
          _isLoadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.agent.businessName ?? 'Unknown Agent';
    final location = widget.agent.location ?? '';
    final description = widget.agent.description ?? '';
    final averageRating = widget.agent.averageRating ?? 0.0;
    final reviewCount = widget.agent.reviewCount ?? 0;
    final specializations = widget.agent.specializations ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoadingPhoto
                  ? CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _userPhotoUrl.isNotEmpty
                          ? NetworkImage(_userPhotoUrl)
                          : null,
                      child: _userPhotoUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey.shade600,
                            )
                          : null,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            if (index < averageRating.floor()) {
                              return Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber.shade700,
                              );
                            } else if (index < averageRating.ceil() && 
                                       averageRating % 1 != 0) {
                              return Icon(
                                Icons.star_half,
                                size: 16,
                                color: Colors.amber.shade700,
                              );
                            } else {
                              return Icon(
                                Icons.star_border,
                                size: 16,
                                color: Colors.grey.shade400,
                              );
                            }
                          }),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          averageRating > 0 
                              ? averageRating.toStringAsFixed(1)
                              : '0.0',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($reviewCount)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                    
                    if (specializations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: specializations
                            .take(3)
                            .map((spec) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    spec.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}