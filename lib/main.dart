import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rbac/core/app_theme.dart';
import 'package:rbac/core/database/warehouse_database.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:rbac/features/onboarding/onboarding_screen.dart';
import 'package:rbac/features/warehouse/warehouse.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const WarehouseStaffApp());
}

class WarehouseStaffApp extends StatefulWidget {
  const WarehouseStaffApp({
    super.key,
    this.database,
    this.showOnboarding = true,
  });

  final Database? database;
  final bool showOnboarding;

  @override
  State<WarehouseStaffApp> createState() => _WarehouseStaffAppState();
}

class _WarehouseStaffAppState extends State<WarehouseStaffApp> {
  late final Future<_AppDeps> _depsFuture = _initAppDeps();
  late bool _onboardingDone = !widget.showOnboarding;

  Future<_AppDeps> _initAppDeps() async {
    final db = widget.database ?? await openWarehouseDatabase();
    final authState = AuthState(LoginService(db));
    await authState.loadUsers();
    return _AppDeps(db: db, authState: authState);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gudang RBAC',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: FutureBuilder<_AppDeps>(
        future: _depsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat database',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final deps = snapshot.data;
          if (deps == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
            );
          }

          return ListenableBuilder(
            listenable: deps.authState,
            builder: (context, _) {
              final user = deps.authState.activeUser;
              if (user == null) {
                if (!_onboardingDone) {
                  return OnboardingScreen(
                    onFinish: () => setState(() => _onboardingDone = true),
                  );
                }
                return DemoLoginScreen(authState: deps.authState);
              }

              return WarehouseHomePage(
                db: deps.db,
                user: user,
                authState: deps.authState,
                onSwitchAccount: deps.authState.switchAccount,
              );
            },
          );
        },
      ),
    );
  }
}

class _AppDeps {
  const _AppDeps({required this.db, required this.authState});

  final Database db;
  final AuthState authState;
}
