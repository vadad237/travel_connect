import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/review_model.dart';

class ReviewProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;

  void listenToAgentReviews(String agentId) {
    _firestoreService.getAgentReviews(agentId).listen((reviews) {
      _reviews = reviews;
      notifyListeners();
    });
  }

  Future<bool> hasUserReviewed(String userId, String agentId) async {
    final review = await _firestoreService.getUserReviewForAgent(userId, agentId);
    return review != null;
  }

  Future<void> createReview(ReviewModel review) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.createReview(review);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}