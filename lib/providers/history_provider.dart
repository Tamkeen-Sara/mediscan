import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/scan_history_model.dart';
import '../services/realtime_db_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<ScanHistoryModel> _allItems = [];
  List<ScanHistoryModel> _filtered = [];
  HistoryFilter _filter = HistoryFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;

  StreamSubscription<List<ScanHistoryModel>>? _historySub;
  StreamSubscription<User?>? _authSub;

  List<ScanHistoryModel> get items => _filtered;
  HistoryFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isEmpty => _filtered.isEmpty;

  HistoryProvider() {
    // Automatically re-initialize whenever auth state changes
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      // Signed out — clear data and cancel listener
      _historySub?.cancel();
      _historySub = null;
      _allItems = [];
      _filtered = [];
      _isLoading = false;
      notifyListeners();
    } else {
      // Signed in — (re)start the history stream
      _startListening(user.uid);
    }
  }

  void _startListening(String uid) {
    _historySub?.cancel();
    _isLoading = true;
    notifyListeners();

    _historySub = RealtimeDatabaseService.instance
        .watchHistory(uid, filter: _filter)
        .listen(
      (items) {
        _allItems = items;
        _isLoading = false;
        _applySearch();
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Called from HistoryScreen to ensure listener is running.
  /// Safe to call multiple times — no-op if already listening.
  void init() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_historySub != null) return; // already running
    _startListening(uid);
  }

  void setFilter(HistoryFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _historySub?.cancel();
    _historySub = RealtimeDatabaseService.instance
        .watchHistory(uid, filter: _filter)
        .listen((items) {
      _allItems = items;
      _applySearch();
      notifyListeners();
    });
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filtered = List.from(_allItems);
      return;
    }
    final q = _searchQuery.toLowerCase();
    _filtered = _allItems
        .where((h) =>
            h.brandName.toLowerCase().contains(q) ||
            h.genericName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> toggleFavourite(ScanHistoryModel item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || item.id.isEmpty) return;
    await RealtimeDatabaseService.instance
        .toggleFavourite(uid, item.id, !item.isFavourite);
  }

  Future<void> deleteItem(String pushKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await RealtimeDatabaseService.instance.deleteHistory(uid, pushKey);
  }

  Future<void> deleteAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await RealtimeDatabaseService.instance.deleteAllHistory(uid);
    _allItems = [];
    _filtered = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
