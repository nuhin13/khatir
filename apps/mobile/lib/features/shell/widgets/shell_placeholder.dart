import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../l10n/app_localizations.dart';

/// Temporary body shown inside a role-shell tab branch until the owning feature
/// epic replaces it with real content. It renders the tab's name plus a
/// "coming soon" caption so the shell structure is verifiable end-to-end.
///
/// Each call site carries a `// TODO(EPIC-NN)` marker naming the epic that
/// fills the branch.
class KShellPlaceholder extends StatelessWidget {
  const KShellPlaceholder({super.key, required this.tabLabel, this.icon});

  /// Human-readable name of the tab this placeholder stands in for.
  final String tabLabel;

  /// Optional leading glyph echoing the nav icon for this branch.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 40, color: KhatirColors.sage),
                  const SizedBox(height: KhatirSpacing.s4),
                ],
                Text(tabLabel, style: theme.textTheme.headlineMedium),
                const SizedBox(height: KhatirSpacing.s2),
                Text(
                  l10n.shell_placeholder_coming_soon(tabLabel),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
