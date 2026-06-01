import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

/// Routable placeholder shown after the splash. Confirms the app boots and
/// that `--dart-define APP_ENV` flows through. Real screens arrive in features.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  static const String routeName = 'placeholder';
  static const String routePath = '/placeholder';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Khatir', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'env: ${AppConfig.appEnv}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
