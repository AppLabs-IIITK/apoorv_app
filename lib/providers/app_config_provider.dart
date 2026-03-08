// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppConfigProvider extends ChangeNotifier {
  List<String> _adminEmails = [];
  List<String> _subAdminEmails = [];
  List<String> _shopkeeperEmails = [];
  String _mode = 'production';
  String _apiMode = 'cloud_functions';
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String get mode => _mode;
  String get apiMode => _apiMode;

  /// Returns true if the currently logged-in user's email is in adminEmails.
  bool get isAdmin {
    final email = _currentEmail;
    if (email == null) return false;
    return _adminEmails.contains(email);
  }

  /// Returns true if the currently logged-in user's email is in subAdminEmails.
  bool get isSubAdmin {
    final email = _currentEmail;
    if (email == null) return false;
    return _subAdminEmails.contains(email);
  }

  /// True for users who can manage feed/maps/events/shopkeepers.
  bool get canManageContent => isAdmin || isSubAdmin;

  /// Returns true if the currently logged-in user's email is in shopkeeperEmails.
  bool get isShopkeeper {
    final email = _currentEmail;
    if (email == null) return false;
    return _shopkeeperEmails.contains(email);
  }

  String? get _currentEmail =>
      FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();

  List<String> _normalizeEmails(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Fetches the global config document from Firestore exactly once.
  /// Call this after authentication is confirmed.
  Future<void> fetchConfig() async {
    if (_isLoading || _isLoaded) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('global')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        _adminEmails = _normalizeEmails(data['adminEmails']);
        _subAdminEmails = _normalizeEmails(data['subAdminEmails']);
        _shopkeeperEmails = _normalizeEmails(data['shopkeeperEmails']);
        _mode = (data['mode'] as String?) ?? 'production';
        _apiMode = (data['apiMode'] as String?) ?? 'cloud_functions';
      } else {
        print('AppConfig: app_config/global not found in Firestore.');
        _adminEmails = [];
        _subAdminEmails = [];
        _shopkeeperEmails = [];
      }

      _isLoaded = true;
    } catch (e) {
      print('AppConfig: Failed to fetch config - $e');
      _adminEmails = [];
      _subAdminEmails = [];
      _shopkeeperEmails = [];
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call this on logout to clear the cached config.
  void clearConfig() {
    _adminEmails = [];
    _subAdminEmails = [];
    _shopkeeperEmails = [];
    _mode = 'production';
    _apiMode = 'cloud_functions';
    _isLoaded = false;
    _isLoading = false;
    notifyListeners();
  }
}
