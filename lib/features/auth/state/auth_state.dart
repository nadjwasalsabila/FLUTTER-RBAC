import 'package:flutter/foundation.dart';

import '../services/login_service.dart';
import '../types/auth_user.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._loginService);

  final LoginService _loginService;

  AuthUser? _activeUser;
  List<AuthUser> _users = const [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get activeUser => _activeUser;
  List<AuthUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _loginService.getUsers();
    } catch (_) {
      _errorMessage = 'Gagal memuat daftar akun demo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthUser?> loginById(int id) async {
    final user = await _loginService.getUserById(id);
    if (user == null) {
      _errorMessage = 'Akun demo tidak ditemukan.';
      notifyListeners();
      return null;
    }
    return selectUser(user) ? user : null;
  }

  Future<AuthUser?> loginByUsername(String username) async {
    final user = await _loginService.getUserByUsername(username);
    if (user == null) {
      _errorMessage = 'Akun demo tidak ditemukan.';
      notifyListeners();
      return null;
    }
    return selectUser(user) ? user : null;
  }

  Future<AuthUser?> loginWithCredentials(
    String identifier,
    String password,
  ) async {
    if (identifier.trim().isEmpty) {
      _errorMessage = 'Email atau username wajib diisi.';
      notifyListeners();
      return null;
    }
    if (password.isEmpty) {
      _errorMessage = 'Password wajib diisi.';
      notifyListeners();
      return null;
    }
    final user = await _loginService.getUserByIdentifier(identifier);
    if (user == null) {
      _errorMessage = 'Akun tidak ditemukan. Gunakan akun demo tersedia.';
      notifyListeners();
      return null;
    }
    return selectUser(user) ? user : null;
  }

  bool selectUser(AuthUser user) {
    if (!user.isActive) {
      _errorMessage = 'Akun ${user.username} sedang tidak aktif.';
      notifyListeners();
      return false;
    }
    _activeUser = user;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void switchAccount() {
    _activeUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
