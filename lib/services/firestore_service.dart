import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_agent_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Travel Agents
  Stream<List<TravelAgentModel>> getAgentsStream() {
    return _firestore
        .collection('travelAgents')
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
      return null;
    }
  }

  Future<String> createAgent(TravelAgentModel agent) async {
    try {
      final docRef = await _firestore.collection('travelAgents').add(agent.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('travelAgents').doc(agentId).update(data);
    } catch (e) {
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
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<ReviewModel>> getAgentReviewsOnce(String agentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
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
      return null;
    }
  }

  Future<void> createReview(ReviewModel review) async {
    try {
      // Check if user already reviewed this agent
      final existingReview = await getUserReviewForAgent(review.userId, review.agentId);
      if (existingReview != null) {
        throw Exception('You have already reviewed this agent');
      }

      // Add the review
      await _firestore.collection('reviews').add(review.toMap());

      // Update the agent's rating and review count
      await _updateAgentRating(review.agentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReview(String reviewId, ReviewModel updatedReview) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updatedReview.toMap());

      // Update the agent's rating
      await _updateAgentRating(updatedReview.agentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      // Get the review first to know which agent to update
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final agentId = reviewDoc.data()?['agentId'] as String?;

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update the agent's rating if we have the agentId
      if (agentId != null) {
        await _updateAgentRating(agentId);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to recalculate and update agent rating
  Future<void> _updateAgentRating(String agentDocId) async {
    try {
      // Verify the agent document exists
      final agentDoc = await _firestore.collection('travelAgents').doc(agentDocId).get();

      if (!agentDoc.exists) {
        return;
      }

      // Get all reviews for this agent (using document ID)
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('agentId', isEqualTo: agentDocId)
          .get();

      final reviews = reviewsSnapshot.docs;
      final reviewCount = reviews.length;

      // Calculate average rating
      double averageRating = 0.0;
      if (reviewCount > 0) {
        double totalRating = 0.0;
        for (var doc in reviews) {
          final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
          totalRating += rating;
        }
        averageRating = totalRating / reviewCount;
      }

      // Update the agent document
      await _firestore.collection('travelAgents').doc(agentDocId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't rethrow - we don't want to fail the review operation if rating update fails
    }
  }
}
