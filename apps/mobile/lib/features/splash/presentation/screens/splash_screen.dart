import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../placeholder/presentation/screens/placeholder_screen.dart';

/// Boot screen. In later epics this decides the next route from auth + role;
/// for the scaffold it simply forwards to the placeholder.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(PlaceholderScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
