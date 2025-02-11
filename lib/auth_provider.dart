import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool isAuthenticated = false;

  AuthProvider() {
    // Charger l'état d'authentification au démarrage
    _loadAuthState();
  }

  void login() async {
    isAuthenticated = true;
    notifyListeners();

    // Sauvegarder l'état d'authentification
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
  }

  void logout() async {
    isAuthenticated = false;
    notifyListeners();

    // Supprimer l'état d'authentification
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    notifyListeners(); // Notifie les widgets après le chargement
  }
}