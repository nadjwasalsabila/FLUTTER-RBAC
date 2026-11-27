import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _teal = AppColors.primaryTeal;
  static const _mint = AppColors.softMint;
  static const _bg = Colors.white;
  static const _title = AppColors.darkText;
  static const _body = AppColors.textMuted;

  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingPageData(
      image: 'assets/onboarding/warehouse_onboarding.png',
      title: 'Kelola Gudang\nLebih Rapi.',
      subtitle:
          'Satu platform untuk mengatur stok, akses tim, dan operasional gudang dengan aman dan terstruktur.',
      chips: ['Akses Berbasis Peran', 'Data Stok Real-time', 'Aman & Terkendali'],
      buttonLabel: 'Lanjutkan',
      helper: 'Geser atau tekan lanjutkan',
    ),
    _OnboardingPageData(
      image: 'assets/onboarding/team_access_onboarding.png',
      title: 'Akses Tim\nSesuai Peran.',
      subtitle:
          'Staff, Manager, dan Admin mendapatkan akses sesuai tanggung jawabnya. Semua tercatat dan terkontrol.',
      chips: ['Staff Gudang', 'Kepala Gudang', 'Admin Sistem'],
      buttonLabel: 'Masuk ke Aplikasi',
      helper: 'Gunakan akun demo untuk mencoba aplikasi',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final page = _pages[_index];
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warehouse_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sistem Gudang RBAC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _title,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinish,
                    style: TextButton.styleFrom(
                      foregroundColor: _body,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Lewati'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottom),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _teal : _mint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(page.buttonLabel),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    page.helper,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _body),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.buttonLabel,
    required this.helper,
  });

  final String image;
  final String title;
  final String subtitle;
  final List<String> chips;
  final String buttonLabel;
  final String helper;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  static const _teal = AppColors.primaryTeal;
  static const _title = AppColors.darkText;
  static const _body = AppColors.textMuted;
  static const _chipBg = AppColors.paleMint;
  static const _chipBorder = AppColors.border;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxHeight * 0.42).clamp(180.0, 340.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: _title,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _body,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: data.chips
                    .map(
                      (chip) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _chipBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _chipBorder),
                        ),
                        child: Text(
                          chip,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _teal,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
