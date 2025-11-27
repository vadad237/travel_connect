import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/travel_agent_model.dart';

class AgentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<TravelAgentModel> _agents = [];
  List<TravelAgentModel> _filteredAgents = [];
  TravelAgentModel? _currentAgentProfile;
  bool _isLoading = false;
  String _searchQuery = '';

  List<TravelAgentModel> get agents => _filteredAgents;
  TravelAgentModel? get currentAgentProfile => _currentAgentProfile;
  bool get isLoading => _isLoading;

  void listenToAgents() {
    _firestoreService.getAgentsStream().listen((agents) {
      _agents = agents;
      _applyFilters();
      notifyListeners();
    });
  }

  void searchAgents(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredAgents = _agents;
    } else {
      _filteredAgents = _agents.where((agent) {
        return agent.businessName.toLowerCase().contains(_searchQuery) ||
            agent.description.toLowerCase().contains(_searchQuery) ||
            agent.location.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<TravelAgentModel?> getAgentById(String agentId) async {
    return await _firestoreService.getAgentById(agentId);
  }

  Future<TravelAgentModel?> getAgentByUserId(String userId) async {
    return await _firestoreService.getAgentByUserId(userId);
  }

  Future<void> loadCurrentAgentProfile(String userId) async {
    _isLoading = true;
    // Schedule notifyListeners for after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _currentAgentProfile = await _firestoreService.getAgentByUserId(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createAgent(TravelAgentModel agent) async {
    _isLoading = true;
    notifyListeners();

    try {
      final agentId = await _firestoreService.createAgent(agent);
      _isLoading = false;
      notifyListeners();
      return agentId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateAgent(agentId, data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void clearCurrentAgentProfile() {
    _currentAgentProfile = null;
  }
}