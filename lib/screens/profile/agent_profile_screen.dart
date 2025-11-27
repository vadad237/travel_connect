import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/agent_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/travel_agent_model.dart';
import '../../widgets/review_card.dart';
import '../reviews/add_review_screen.dart';
import '../chat/chat_room_screen.dart';

class AgentProfileScreen extends StatefulWidget {
  final String agentId;

  const AgentProfileScreen({Key? key, required this.agentId}) : super(key: key);

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  TravelAgentModel? _agent;
  String _userPhotoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    reviewProvider.listenToAgentReviews(widget.agentId);
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final agent = await agentProvider.getAgentById(widget.agentId);
    
    if (agent != null) {
      // Fetch user's photo from users collection
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(agent.userId)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          _userPhotoUrl = userData?['photoUrl'] as String? ?? '';
        }
      } catch (e) {
        // Silently handle error
      }
    }
    
    if (mounted) {
      setState(() {
        _agent = agent;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMessageTap() async {
    if (_agent == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to send messages')),
        );
      }
      return;
    }

    // Don't allow messaging yourself
    if (currentUser.id == _agent!.userId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')),
        );
      }
      return;
    }

    try {
      final chatId = await chatProvider.getOrCreateChat(
        currentUser.id,
        _agent!.userId,
        {
          'name': currentUser.displayName,
          'photo': currentUser.photoUrl,
        },
        {
          'name': _agent!.businessName,
          'photo': _userPhotoUrl,
        },
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chatId: chatId,
              otherUserName: _agent!.businessName,
              otherUserPhoto: _userPhotoUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleWriteReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to write a review')),
        );
      }
      return;
    }

    // Don't allow reviewing yourself
    if (currentUser.id == _agent!.userId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot review your own profile')),
        );
      }
      return;
    }

    // Check if user already reviewed
    final hasReviewed = await reviewProvider.hasUserReviewed(
      currentUser.id,
      widget.agentId,
    );

    if (hasReviewed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this agent')),
      );
      return;
    }

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddReviewScreen(
            agentId: widget.agentId,
            agentName: _agent!.businessName,
          ),
        ),
      );

      // Reload agent data if review was added
      if (result == true) {
        await _loadAgentData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_agent == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Agent not found')),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isOwnProfile = currentUser?.id == _agent!.userId;
    final isCurrentUserAgent = currentUser?.role == 'agent';

    return Scaffold(
      appBar: AppBar(
        title: Text(_agent!.businessName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAgentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _userPhotoUrl.isNotEmpty
                          ? NetworkImage(_userPhotoUrl)
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _agent!.businessName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _agent!.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RatingBarIndicator(
                          rating: _agent!.averageRating,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_agent!.averageRating.toStringAsFixed(1)} (${_agent!.reviewCount} reviews)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    // Only show buttons if current user is not an agent and not viewing own profile
                    if (!isOwnProfile && !isCurrentUserAgent) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleMessageTap,
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleWriteReview,
                              icon: const Icon(Icons.rate_review),
                              label: const Text('Write Review'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // About Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _agent!.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    if (_agent!.specializations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Specializations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _agent!.specializations.map((spec) {
                          return Chip(
                            label: Text(spec),
                            backgroundColor: Colors.blue.shade100,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(thickness: 8),

              // Reviews Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_agent!.reviewCount} total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<ReviewProvider>(
                      builder: (context, reviewProvider, child) {
                        if (reviewProvider.reviews.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviewProvider.reviews.length,
                          separatorBuilder: (context, index) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            return ReviewCard(
                              review: reviewProvider.reviews[index],
                            );
                          },
                        );
                      },
                    ),
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