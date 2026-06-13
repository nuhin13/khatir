import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/data/profile_providers.dart';
import '../widgets/role_card.dart';

/// Static, design-driven description of a self-selectable role (a `ROLE_CARDS`
/// entry in the `roleChooser` prototype): which [Role] it persists, the shell
/// route it lands in, and its accent palette. Copy is resolved from l10n at
/// build time so it stays out of this table.
class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.emoji,
    required this.shellPath,
    required this.background,
    required this.accent,
    required this.accentDark,
    this.recommended = false,
  });

  final Role role;
  final String emoji;

  /// Destination shell home once the role is persisted.
  final String shellPath;
  final Color background;
  final Color accent;
  final Color accentDark;

  /// Whether this is the "most common ⭐" recommended role.
  final bool recommended;
}

/// Role chooser (T-005): a newly-verified user declares whether they are a
/// landlord, building manager, or tenant. Selecting a card persists the role
/// via [ProfileController.setRole] (T-003) and then routes into that role's
/// shell home. Mirrors the `roleChooser` prototype; reachable again later via
/// More → switch role.
///
/// Caretaker is intentionally NOT offered here — it is assigned later (P2).
class RoleChooserScreen extends ConsumerStatefulWidget {
  const RoleChooserScreen({super.key});

  static const String routeName = 'role';
  static const String routePath = '/role';

  @override
  ConsumerState<RoleChooserScreen> createState() => _RoleChooserScreenState();
}

class _RoleChooserScreenState extends ConsumerState<RoleChooserScreen> {
  /// The role whose selection is currently being persisted, or null when idle.
  Role? _persisting;

  /// Self-selectable roles in display order (landlord first, recommended).
  static const List<_RoleOption> _options = [
    _RoleOption(
      role: Role.landlord,
      emoji: '🏠',
      shellPath: '/landlord/home',
      background: KhatirColors.sageBg,
      accent: KhatirColors.sage,
      accentDark: KhatirColors.sageDk,
      recommended: true,
    ),
    _RoleOption(
      role: Role.manager,
      emoji: '🏢',
      shellPath: '/manager/home',
      background: KhatirColors.butterBg,
      accent: KhatirColors.butter,
      accentDark: KhatirColors.butterDk,
    ),
    _RoleOption(
      role: Role.tenant,
      emoji: '👤',
      shellPath: '/tenant/home',
      background: KhatirColors.roseBg,
      accent: KhatirColors.rose,
      accentDark: KhatirColors.roseDk,
    ),
  ];

  bool get _isPersisting => _persisting != null;

  Future<void> _select(_RoleOption option) async {
    if (_isPersisting) return;
    setState(() => _persisting = option.role);
    try {
      // Persist BEFORE routing so the chosen role is the DB source of truth.
      await ref.read(profileProvider.notifier).setRole(option.role);
      if (!mounted) return;
      context.go(option.shellPath);
    } on ApiException {
      if (!mounted) return;
      setState(() => _persisting = null);
      _showError();
    } catch (_) {
      if (!mounted) return;
      setState(() => _persisting = null);
      _showError();
    }
  }

  void _showError() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.common_network_error)),
      );
  }

  String _nameBn(AppLocalizations l10n, Role role) => switch (role) {
        Role.landlord => l10n.role_landlord_bn,
        Role.manager => l10n.role_manager_bn,
        Role.tenant => l10n.role_tenant_bn,
        _ => '',
      };

  String _nameEn(AppLocalizations l10n, Role role) => switch (role) {
        Role.landlord => l10n.role_landlord_en,
        Role.manager => l10n.role_manager_en,
        Role.tenant => l10n.role_tenant_en,
        _ => '',
      };

  String _desc(AppLocalizations l10n, Role role) => switch (role) {
        Role.landlord => l10n.role_landlord_desc,
        Role.manager => l10n.role_manager_desc,
        Role.tenant => l10n.role_tenant_desc,
        _ => '',
      };

  List<String> _perks(AppLocalizations l10n, Role role) => switch (role) {
        Role.landlord => [
            l10n.role_landlord_perk1,
            l10n.role_landlord_perk2,
            l10n.role_landlord_perk3,
          ],
        Role.manager => [
            l10n.role_manager_perk1,
            l10n.role_manager_perk2,
            l10n.role_manager_perk3,
          ],
        Role.tenant => [
            l10n.role_tenant_perk1,
            l10n.role_tenant_perk2,
            l10n.role_tenant_perk3,
          ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                KhatirSpacing.s5,
                KhatirSpacing.s4,
                KhatirSpacing.s5,
                KhatirSpacing.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: handwritten hero + Bangla title + subtitle.
                  Text(
                    l10n.role_hero,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.accent.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: KhatirSpacing.s1),
                  Text(
                    l10n.role_title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: KhatirSpacing.s1),
                  Text(
                    l10n.role_subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: KhatirSpacing.s5),
                  // Role cards.
                  for (final option in _options) ...[
                    RoleCard(
                      emoji: option.emoji,
                      nameBn: _nameBn(l10n, option.role),
                      nameEn: _nameEn(l10n, option.role),
                      description: _desc(l10n, option.role),
                      perks: _perks(l10n, option.role),
                      background: option.background,
                      accent: option.accent,
                      accentDark: option.accentDark,
                      mostCommonLabel:
                          option.recommended ? l10n.role_most_common : null,
                      enabled: !_isPersisting,
                      onTap: () => _select(option),
                    ),
                    const SizedBox(height: KhatirSpacing.s3),
                  ],
                  const SizedBox(height: KhatirSpacing.s2),
                  Text(
                    l10n.role_change_later,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            // Loading overlay while a selection persists.
            if (_isPersisting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
