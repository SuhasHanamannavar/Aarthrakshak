import 'package:flutter/foundation.dart';
import '../models/archetype.dart';

class AppState extends ChangeNotifier {
  Archetype? _currentArchetype;

  Archetype? get currentArchetype => _currentArchetype;

  void setArchetype(Archetype a) {
    _currentArchetype = a;
    notifyListeners();
  }
}
