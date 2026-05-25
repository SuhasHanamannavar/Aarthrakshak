import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/archetype.dart';

class AppState extends ChangeNotifier {
  User? _supabaseUser;
  String? _jwtToken;
  Archetype? _currentArchetype;
  List<dynamic> _transactionsList = [];
  Map<String, dynamic>? _dashboardData;

  User? get supabaseUser => _supabaseUser;
  String? get jwtToken => _jwtToken;
  Archetype? get currentArchetype => _currentArchetype;
  List<dynamic> get transactionsList => _transactionsList;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  void setUser(User? user, String? token) {
    _supabaseUser = user;
    _jwtToken = token;
    notifyListeners();
  }

  void setArchetype(Archetype? a) {
    _currentArchetype = a;
    notifyListeners();
  }

  void setTransactions(List<dynamic> txs) {
    _transactionsList = txs;
    notifyListeners();
  }

  void addTransaction(dynamic tx) {
    _transactionsList.insert(0, tx);
    notifyListeners();
  }

  void setDashboardData(Map<String, dynamic> data) {
    _dashboardData = data;
    notifyListeners();
  }
}
