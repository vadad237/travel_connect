import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    reviewProvider.listenToAgentReviews(widget.agentId);
  }

  Future<void> _loadAgentData() async {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final agent = await agentProvider.getAgentById(widget.agentId);
    setState(() {
      _agent = agent;
      _isLoading = false;
    });
  }

  Future<void> _handleMessageTap() async {
    if (_agent == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

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
          'photo': _agent!.profilePhoto,
        },
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chatId: chatId,
              otherUserName: _agent!.businessName,
              otherUserPhoto: _agent!.profilePhoto,
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

    if (currentUser == null) return;

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddReviewScreen(
            agentId: widget.agentId,
            agentName: _agent!.businessName,
          ),
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_agent!.businessName),
      ),
      body: SingleChildScrollView(
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
                    backgroundImage: _agent!.profilePhoto.isNotEmpty
                        ? NetworkImage(_agent!.profilePhoto)
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
                  const SizedBox(height: 8),
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
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviewProvider.reviews.length,
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
    );
  }
}