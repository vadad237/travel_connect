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
      print('🔵 [FirestoreService] Getting agent by ID: $agentId');
      final doc =
          await _firestore.collection('travelAgents').doc(agentId).get();
      if (doc.exists) {
        print('✅ [FirestoreService] Agent found');
        return TravelAgentModel.fromMap(doc.data()!, doc.id);
      }
      print('🟡 [FirestoreService] Agent not found');
      return null;
    } catch (e) {
      print('🔴 [FirestoreService] Error getting agent: $e');
      return null;
    }
  }

  Future<TravelAgentModel?> getAgentByUserId(String userId) async {
    try {
      print('🔵 [FirestoreService] Getting agent by userId: $userId');
      final querySnapshot = await _firestore
          .collection('travelAgents')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ [FirestoreService] Agent found');
        return TravelAgentModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      print('🟡 [FirestoreService] No agent found with userId: $userId');
      return null;
    } catch (e) {
      print('🔴 [FirestoreService] Error getting agent by user ID: $e');
      return null;
    }
  }

  Future<String> createAgent(TravelAgentModel agent) async {
    try {
      print('🔵 [FirestoreService] Creating agent');
      final docRef =
          await _firestore.collection('travelAgents').add(agent.toMap());
      print('✅ [FirestoreService] Agent created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔴 [FirestoreService] Error creating agent: $e');
      rethrow;
    }
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      print('🔵 [FirestoreService] Updating agent: $agentId');
      await _firestore.collection('travelAgents').doc(agentId).update(data);
      print('✅ [FirestoreService] Agent updated');
    } catch (e) {
      print('🔴 [FirestoreService] Error updating agent: $e');
      rethrow;
    }
  }

  // Reviews
  Stream<List<ReviewModel>> getAgentReviews(String agentId) {
    print('🔵 [FirestoreService] Listening to reviews for agent: $agentId');
    return _firestore
        .collection('reviews')
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔵 [FirestoreService] Received ${snapshot.docs.length} reviews');
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<ReviewModel>> getAgentReviewsOnce(String agentId) async {
    try {
      print('🔵 [FirestoreService] Loading reviews for agent: $agentId');
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ [FirestoreService] Loaded ${querySnapshot.docs.length} reviews');
      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('🔴 [FirestoreService] Error getting agent reviews: $e');
      rethrow;
    }
  }

  Future<ReviewModel?> getUserReviewForAgent(
      String userId, String agentId) async {
    try {
      print(
          '🔵 [FirestoreService] Checking if user $userId reviewed agent $agentId');
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('agentId', isEqualTo: agentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ [FirestoreService] User has already reviewed this agent');
        return ReviewModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      print('🟡 [FirestoreService] User has not reviewed this agent');
      return null;
    } catch (e) {
      print('🔴 [FirestoreService] Error getting user review: $e');
      return null;
    }
  }

  Future<void> createReview(ReviewModel review) async {
    try {
      print(
          '🔵 [FirestoreService] Creating review for agent: ${review.agentId}');

      // Check if user already reviewed this agent
      final existingReview =
          await getUserReviewForAgent(review.userId, review.agentId);
      if (existingReview != null) {
        throw Exception('You have already reviewed this agent');
      }

      // Add the review
      await _firestore.collection('reviews').add(review.toMap());
      print('✅ [FirestoreService] Review created');

      // Update the agent's rating and review count
      await _updateAgentRating(review.agentId);
      print('✅ [FirestoreService] Agent rating updated');
    } catch (e) {
      print('🔴 [FirestoreService] Error creating review: $e');
      rethrow;
    }
  }

  Future<void> updateReview(String reviewId, ReviewModel updatedReview) async {
    try {
      print('🔵 [FirestoreService] Updating review: $reviewId');

      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updatedReview.toMap());
      print('✅ [FirestoreService] Review updated');

      // Update the agent's rating
      await _updateAgentRating(updatedReview.agentId);
      print('✅ [FirestoreService] Agent rating updated');
    } catch (e) {
      print('🔴 [FirestoreService] Error updating review: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      print('🔵 [FirestoreService] Deleting review: $reviewId');

      // Get the review first to know which agent to update
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final agentId = reviewDoc.data()?['agentId'] as String?;

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();
      print('✅ [FirestoreService] Review deleted');

      // Update the agent's rating if we have the agentId
      if (agentId != null) {
        await _updateAgentRating(agentId);
        print('✅ [FirestoreService] Agent rating updated');
      }
    } catch (e) {
      print('🔴 [FirestoreService] Error deleting review: $e');
      rethrow;
    }
  }

  // Helper method to recalculate and update agent rating
  // Helper method to recalculate and update agent rating
  // Helper method to recalculate and update agent rating
  Future<void> _updateAgentRating(String agentDocId) async {
    try {
      print(
          '🔵 [FirestoreService] Updating rating for agent document: $agentDocId');

      // Verify the agent document exists
      final agentDoc =
          await _firestore.collection('travelAgents').doc(agentDocId).get();

      if (!agentDoc.exists) {
        print('🔴 [FirestoreService] Agent document not found: $agentDocId');
        return;
      }

      print('✅ [FirestoreService] Agent document found');

      // Get all reviews for this agent (using document ID)
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('agentId', isEqualTo: agentDocId)
          .get();

      final reviews = reviewsSnapshot.docs;
      final reviewCount = reviews.length;

      print('🔵 [FirestoreService] Found $reviewCount reviews');

      // Calculate average rating
      double averageRating = 0.0;
      if (reviewCount > 0) {
        double totalRating = 0.0;
        for (var doc in reviews) {
          final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
          totalRating += rating;
          print('🔵 [FirestoreService] Review ${doc.id}: rating $rating');
        }
        averageRating = totalRating / reviewCount;
      }

      print(
          '🔵 [FirestoreService] Calculated - Rating: ${averageRating.toStringAsFixed(2)}, Count: $reviewCount');

      // Update the agent document
      await _firestore.collection('travelAgents').doc(agentDocId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '✅ [FirestoreService] Agent $agentDocId updated - Rating: ${averageRating.toStringAsFixed(2)}, Count: $reviewCount');
    } catch (e) {
      print('🔴 [FirestoreService] Error updating agent rating: $e');
      // Don't rethrow - we don't want to fail the review operation if rating update fails
    }
  }
}
