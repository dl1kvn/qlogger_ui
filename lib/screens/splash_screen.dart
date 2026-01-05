import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  String? _bgImagePath;
  String _splashText = 'Built for operators';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    Future.delayed(const Duration(milliseconds: 3000), () {
      Get.off(() => const MainShell());
    });
  }

  void _loadSettings() {
    final storage = GetStorage();
    final path = storage.read<String>('splash_bg_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _bgImagePath = path;
      });
    }
    final text = storage.read<String>('splash_text');
    if (text != null && text.isNotEmpty) {
      setState(() {
        _splashText = text;
      });
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image: custom or default with zoom animation
          AnimatedBuilder(
            animation: c,
            builder: (context, child) {
              final scale = 1.0 + (0.33 * c.value);
              return Transform.scale(scale: scale, child: child);
            },
            child: _bgImagePath != null
                ? Image.file(File(_bgImagePath!), fit: BoxFit.cover)
                : Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
          ),
          Center(
            child: FadeTransition(
              opacity: c,
              child: ScaleTransition(
                scale: Tween(begin: 0.90, end: 1.0).animate(c),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'QLOGGER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 33,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _splashText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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
