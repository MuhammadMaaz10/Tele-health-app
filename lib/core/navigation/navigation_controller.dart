import 'package:flutter/material.dart';

class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void switchToTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void switchToAppointments() {
    switchToTab(1);
  }
  
  void switchToDashboard() {
    switchToTab(0);
  }
  
  void switchToProfile() {
    switchToTab(2);
  }
}

