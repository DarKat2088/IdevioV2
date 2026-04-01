import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:idea_generator_app_v2/services/ai_service.dart';
import '../services/ai_service.dart';

class IdeaState extends ChangeNotifier {
  final List<String> favoritesIdeas = [];
  final List<String> historyIdeas = [];
  User? _user;

  IdeaState({User? user}) {
  _user = user;

  FirebaseAuth.instance.authStateChanges().listen((user) {
    _user = user;

    if (user == null) {
      logout();
    } else {
      _loadData();
    }
  });

  _loadData();
}

  final AiRenderService aiService = AiRenderService();

  Future<String> generateAiIdea(String category) async {
    final idea = await aiService.generateIdea(category);

    historyIdeas.insert(0, idea);
    notifyListeners();

    return idea;
  }


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Устанавливаем пользователя после логина
  void setUser(User user) {
    _user = user;
    _loadData();
  }
  
  void logout() {
    _user = null;
    historyIdeas.clear();
    favoritesIdeas.clear();
    notifyListeners();
  }
  /// Загружаем локальные и Firebase данные
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Локальные данные
    final localHistory = prefs.getStringList('historyIdeas') ?? [];
    final localFavorites = prefs.getStringList('favoritesIdeas') ?? [];

    historyIdeas
      ..clear()
      ..addAll(localHistory);
    favoritesIdeas
      ..clear()
      ..addAll(localFavorites);

    // Firebase
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        final data = doc.data();
        if (data != null) {
          if (data['ideaHistory'] != null) {
            historyIdeas
              ..clear()
              ..addAll(List<String>.from(data['ideaHistory']));
          }
          if (data['favoritesIdeas'] != null) {
            favoritesIdeas
              ..clear()
              ..addAll(List<String>.from(data['favoritesIdeas']));
          }
        }
      } catch (e) {
        print("Ошибка загрузки данных из Firebase: $e");
      }
    }

    notifyListeners();
  }

  /// Добавляем идею в историю
  Future<void> addToHistory(String idea) async {
    
    historyIdeas.remove(idea);
    historyIdeas.insert(0, idea);
    notifyListeners();
    print("USER: $_user");
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('historyIdeas', historyIdeas);

    print("UID: ${_user?.uid}, идеи в истории: ${historyIdeas.length}");

    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).set({
          'ideaHistory': historyIdeas,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Ошибка сохранения истории в Firebase: $e");
      }
    }
  }

  /// Добавляем/удаляем из избранного
  Future<void> toggleFavorite(String idea) async {
    if (favoritesIdeas.contains(idea)) {
      favoritesIdeas.remove(idea);
    } else {
      favoritesIdeas.add(idea);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favoritesIdeas', favoritesIdeas);

    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).set({
          'favoritesIdeas': favoritesIdeas,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Ошибка сохранения избранного в Firebase: $e");
      }
    }
  }

  /// Удаляем идею из истории и избранного
  Future<void> removeFromHistory(String idea) async {
    historyIdeas.remove(idea);
    favoritesIdeas.remove(idea);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('historyIdeas', historyIdeas);
    prefs.setStringList('favoritesIdeas', favoritesIdeas);

    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).set({
          'ideaHistory': historyIdeas,
          'favoritesIdeas': favoritesIdeas,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Ошибка обновления данных в Firebase: $e");
      }
    }
  }
}