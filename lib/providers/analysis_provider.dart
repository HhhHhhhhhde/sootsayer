import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';

class AnalysisProvider extends ChangeNotifier {
  final List<AnalysisResult> _results = [];

  List<AnalysisResult> get results => _results;
  
  List<AnalysisResult> get recentResults => 
      _results.take(3).toList();

  void addResult(AnalysisResult result) {
    _results.insert(0, result);
    notifyListeners();
  }

  void updateResult(String id, {
    String? status,
    int? vulnerabilities,
    String? riskLevel,
  }) {
    final index = _results.indexWhere((r) => r.id == id);
    if (index != -1) {
      _results[index] = _results[index].copyWith(
        status: status,
        vulnerabilities: vulnerabilities,
        riskLevel: riskLevel,
      );
      notifyListeners();
    }
  }

  void cancelTask(String id) {
    final index = _results.indexWhere((r) => r.id == id);
    if (index != -1) {
      _results[index] = _results[index].copyWith(status: 'cancelled');
      notifyListeners();
    }
  }

  AnalysisResult? getResultById(String id) {
    try {
      return _results.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  int get totalAnalyses => _results.length;
  
  int get completedAnalyses => 
      _results.where((r) => r.status == 'completed').length;
  
  int get totalVulnerabilities => 
      _results.fold(0, (sum, r) => sum + (r.vulnerabilities ?? 0));
}
