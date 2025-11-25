import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_agent_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Travel Agents
  Stream<List<TravelAgentModel>> getAgentsStream() {
    return _firestore
        .collection('travelAgents')
        .where('isActive', isEqualTo: true)
        .orderBy('averageRating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TravelAgentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<TravelAgentModel?> getAgentById(String agentId) async {
    try {
      final doc = await _firestore.collection('travelAgents').doc(agentId).get();
      if (doc.exists) {
        return TravelAgentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting agent: $e');
      return null;
    }
  }

  Future<TravelAgentModel?> getAgentByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('travelAgents')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TravelAgentModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting agent by user ID: $e');
      return null;
    }
  }

  Future<String> createAgent(TravelAgentModel agent) async {
    try {
      final docRef = await _firestore.collection('travelAgents').add(agent.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating agent: $e');
      rethrow;
    }
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('travelAgents').doc(agentId).update(data);
    } catch (e) {
      print('Error updating agent: $e');
      rethrow;
    }
  }

  // Reviews
  Stream<List<ReviewModel>> getAgentReviews(String agentId) {
    return _firestore
        .collection('reviews')
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<ReviewModel?> getUserReviewForAgent(String userId, String agentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('agentId', isEqualTo: agentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ReviewModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }

  Future<void> createReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').add(review.toMap());
      await _updateAgentRating(review.agentId);
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  Future<void> _updateAgentRating(String agentId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('agentId', isEqualTo: agentId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;
      final reviewCount = reviewsSnapshot.docs.length;

      await _firestore.collection('travelAgents').doc(agentId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
      });
    } catch (e) {
      print('Error updating agent rating: $e');
    }
  }
}