import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final List<AnalysisResult> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  String? _token;

  List<AnalysisResult> get results => _results;
  List<AnalysisResult> get recentResults => _results.take(3).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAnalyses => _results.length;
  int get completedAnalyses =>
      _results.where((r) => r.status == 'COMPLETED').length;
  int get totalVulnerabilities =>
      _results.fold(0, (sum, r) => sum + (r.vulnerabilities ?? 0));

  /// Call this after login, passing the session token.
  void setToken(String token) {
    _token = token;
    fetchTasks();
    _startPolling();
  }

  /// Call this on logout.
  void clearToken() {
    _token = null;
    _pollTimer?.cancel();
    _results.clear();
    notifyListeners();
  }

  /// Fetch full task history from GET /api/tasks.
  Future<void> fetchTasks() async {
    if (_token == null || _token!.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.getTasks(_token!);
      final code = resp['code'];
      final isSuccess = code == 200 || code == 0;
      if (isSuccess && resp['data'] != null) {
        final data = resp['data'];
        List<dynamic> items;
        if (data is Map && data.containsKey('content')) {
          items = data['content'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }
        final fetched = items
            .whereType<Map<String, dynamic>>()
            .map(AnalysisResult.fromTaskJson)
            .toList();
        // Merge: keep locally-added tasks not yet returned by server,
        // update existing ones.
        for (final f in fetched) {
          final idx = _results.indexWhere((r) => r.taskId == f.taskId);
          if (idx == -1) {
            _results.add(f);
          } else {
            _results[idx] = f;
          }
        }
        // Sort newest first
        _results.sort((a, b) => b.submitTime.compareTo(a.submitTime));
      } else {
        _error = resp['message']?.toString() ?? resp['msg']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a freshly-submitted task (before server confirms).
  void addResult(AnalysisResult result) {
    final idx = _results.indexWhere((r) => r.taskId == result.taskId);
    if (idx == -1) {
      _results.insert(0, result);
    } else {
      _results[idx] = result;
    }
    notifyListeners();
  }

  void cancelTask(String id) {
    final index = _results.indexWhere((r) => r.id == id);
    if (index != -1) {
      _results[index] = _results[index].copyWith(status: 'CANCELLED');
      notifyListeners();
    }
  }

  void updateResultStatus(String id, String status) {
    final index = _results.indexWhere((r) => r.id == id);
    if (index != -1) {
      _results[index] = _results[index].copyWith(status: status);
      notifyListeners();
    }
  }

  AnalysisResult? getResultById(String id) {
    try {
      return _results.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollPendingTasks();
    });
  }

  Future<void> _pollPendingTasks() async {
    if (_token == null || _token!.isEmpty) return;
    final pending = _results.where((r) => !r.isTerminal).toList();
    if (pending.isEmpty) return;

    bool changed = false;
    for (final task in pending) {
      try {
        final resp = await ApiService.getTaskStatus(_token!, task.taskId);
        final code = resp['code'];
        final isSuccess = code == 200 || code == 0;
        if (isSuccess && resp['data'] != null) {
          final data = resp['data'] as Map<String, dynamic>;
          final idx = _results.indexWhere((r) => r.taskId == task.taskId);
          if (idx != -1) {
            _results[idx] = _results[idx].withStatusJson(data);
            changed = true;
          }
        }
      } catch (e) {
        debugPrint('Poll error for task ${task.taskId}: $e');
      }
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
