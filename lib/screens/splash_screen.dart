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
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
        ..forward();

  String? _bgImagePath;

  @override
  void initState() {
    super.initState();
    _loadBgImage();
    Future.delayed(const Duration(milliseconds: 2000), () {
      Get.off(() => const MainShell());
    });
  }

  void _loadBgImage() {
    final storage = GetStorage();
    final path = storage.read<String>('splash_bg_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _bgImagePath = path;
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
          // Background image: custom or default
          if (_bgImagePath != null)
            Image.file(
              File(_bgImagePath!),
              fit: BoxFit.cover,
            )
          else
            Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          Center(
            child: FadeTransition(
              opacity: c,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(c),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'QLOGGER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Built for operators',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                          ),
                        ],
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
