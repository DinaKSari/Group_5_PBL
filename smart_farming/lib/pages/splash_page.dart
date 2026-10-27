import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../core/app_colors.dart';

class _SplashSlideData {
  const _SplashSlideData({
    required this.image,
    required this.badgeIcon,
    required this.badgeText,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final IconData badgeIcon;
  final String badgeText;
  final String title;
  final String subtitle;
}

const _slides = [
  _SplashSlideData(
    image: 'assets/images/splash_slide_1.jpg',
    badgeIcon: Icons.eco_rounded,
    badgeText: 'Smart Hydroponic',
    title: 'The Next Generation\nof Lettuce Farming',
    subtitle: 'Pantau pertumbuhan selada hidroponik & prediksi waktu panen akurat dengan model Machine Learning cerdas.',
  ),
  _SplashSlideData(
    image: 'assets/images/splash_slide_2.jpg',
    badgeIcon: Icons.sensors_rounded,
    badgeText: 'IoT Sensor Monitoring',
    title: 'Kontrol Nutrisi &\nLingkungan Presisi',
    subtitle: 'Pantau pH air, nutrisi PPM AB Mix, suhu, dan kelembapan secara real-time untuk pertumbuhan selada optimal.',
  ),
  _SplashSlideData(
    image: 'assets/images/splash_slide_3.jpg',
    badgeIcon: Icons.auto_graph_rounded,
    badgeText: 'Prediksi Panen ML',
    title: 'Estimasi Waktu Panen\nLebih Akurat',
    subtitle: 'Model Machine Learning menghitung sisa hari menuju panen optimal selada Anda agar hasil panen segar maksimal.',
  ),
];

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final cardHeight = (size.height * 0.44).clamp(320.0, 360.0);
    final imageHeight = size.height - cardHeight + 36;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF1EB),
      body: Stack(
        children: [
          // 1. Sliding Pages (Image + Badge + Title + Subtitle)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, i) {
              final slide = _slides[i];
              return Stack(
                children: [
                  // Top Image Illustration
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide.image,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.2),
                        ),
                        // Gradient transition
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 70,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Badge on image
                        Positioned(
                          top: topPadding + 16,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(slide.badgeIcon, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  slide.badgeText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Card Text Area
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: cardHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -6)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                      child: Column(
                        children: [
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Skip ("Lewati") button at top right
          Positioned(
            top: topPadding + 14,
            right: 18,
            child: TextButton(
              onPressed: () => context.go(AppRoute.login),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: AppColors.text,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
              ),
              child: const Text('Lewati', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),

          // 3. Fixed Bottom Controls (Animated Dots + Action Buttons)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated 3-bullet indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = _currentPage == index;
                        return GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.accent : const Color(0xFFD4DAD6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action Button (Lanjutkan -> Mulai Sekarang)
                    FilledButton(
                      onPressed: _onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.darkBtn,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'Mulai Sekarang' : 'Lanjutkan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _slides.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secondary Direct Bypass Button
                    TextButton(
                      onPressed: () => context.go(AppRoute.home),
                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                      child: const Text(
                        'Masuk Langsung sebagai Tamu',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
