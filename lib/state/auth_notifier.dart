import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../core/api_exceptions.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  
  final SharedPreferences _prefs;
  final Dio Function() _getDio;

  AuthNotifier(this._prefs, this._getDio);

  AppUser? _user;
  String? _accessToken;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  bool hasRole(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null) return;

    _accessToken = access;
    try {
      final response = await _getDio().get('/auth/me');
      _user = AppUser.fromJson(response.data as Map<String, dynamic>);
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final response = await _getDio().post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    
    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, data['refreshToken'] as String);
    notifyListeners();
  }

  Future<void> register(String username, String password, String email, String fullName) async {
    await _getDio().post('/auth/register', data: {
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
    });
    await login(username, password);
  }

  Future<void> _refreshWith(String refreshToken) async {
    final response = await _getDio().post('/auth/refresh', data: {'refreshToken': refreshToken});
    final data = response.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    
    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, data['refreshToken'] as String);
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) throw Exception('No refresh token');
    await _refreshWith(refresh);
  }

  Future<void> logout() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh != null) {
      try {
        await _getDio().post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {}
    }
    _user = null;
    _accessToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    notifyListeners();
  }
}