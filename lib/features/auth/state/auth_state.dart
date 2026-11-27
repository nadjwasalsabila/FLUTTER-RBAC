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

  /// Role yang bisa dibuat:
  /// - Dari layar publik login: HANYA staff (role 'staff').
  /// - Dari beranda admin: HANYA manager (dan staff bila perlu).
  /// Role admin TIDAK PERNAH bisa dibuat lewat form buat akun.
  static const publicRoles = ['staff'];
  static const adminCreatableRoles = ['manager', 'staff'];

  @Deprecated('Gunakan publicRoles atau adminCreatableRoles')
  static const availableRoles = ['staff', 'manager'];

  /// Password demo standar untuk semua akun seeder (akun lama tanpa
  /// password kustom memakai ini).
  static const demoPassword = 'demo123';

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
    final stored = await _loginService.getPasswordForUsername(
      user.username,
    );
    if (password != (stored ?? demoPassword)) {
      _errorMessage = 'Password salah. Coba lagi.';
      notifyListeners();
      return null;
    }
    return selectUser(user) ? user : null;
  }

  /// Membuat akun baru lalu langsung login sebagai akun tersebut.
  /// Mengembalikan error message jika gagal, null jika sukses.
  Future<String?> registerAndLogin({
    required String fullName,
    required String username,
    required String password,
    required String roleId,
  }) async {
    if (!publicRoles.contains(roleId)) {
      const msg = 'Pendaftaran hanya tersedia untuk role staff.';
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }
    final error = await _loginService.createUser(
      fullName: fullName,
      username: username,
      password: password,
      roleId: roleId,
    );
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return error;
    }
    final user = await _loginService.getUserByUsername(username);
    if (user == null) {
      _errorMessage = 'Gagal membuat akun.';
      notifyListeners();
      return 'Gagal membuat akun.';
    }
    await loadUsers();
    return selectUser(user) ? null : (_errorMessage ?? 'Gagal membuat akun.');
  }

  /// Membuat akun baru tanpa otomatis login (mis. saat dibuat oleh Admin).
  /// Mengembalikan error message jika gagal, null jika sukses.
  Future<String?> createAccountWithoutLogin({
    required String fullName,
    required String username,
    required String password,
    required String roleId,
  }) async {
    if (!adminCreatableRoles.contains(roleId)) {
      const msg = 'Admin hanya dapat membuat akun manager atau staff.';
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }
    final error = await _loginService.createUser(
      fullName: fullName,
      username: username,
      password: password,
      roleId: roleId,
    );
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return error;
    }
    await loadUsers();
    return null;
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
