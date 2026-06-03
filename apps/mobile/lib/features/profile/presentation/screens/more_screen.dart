import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/screens/phone_entry_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../role/presentation/screens/role_chooser_screen.dart';
import '../widgets/more_row.dart';

/// The More menu — the per-role settings hub, mirroring the `more` prototype:
/// a sage profile header (avatar, name, masked phone + role, plan chip), a card
/// of action rows (profile, plan & billing, AI lease, warnings, language,
/// switch role, about), and a rose logout button.
///
/// Hosted by every role shell's More tab via [MoreScreen.forRole]; landlord and
/// manager see the full row set while tenants get the simpler list (no AI
/// lease / warnings rows). All colors/spacing/radii come from the design
/// tokens.
///
/// Behaviours:
/// * **Language** toggles the app locale in place via [LocaleController.toggle]
///   (persisted by [localeProvider]) — no route change.
/// * **Switch role** routes to the role chooser ([RoleChooserScreen]).
/// * **About** routes to onboarding ([OnboardingScreen]).
/// * **Logout** calls [AuthController.logout] then sends the user to phone
///   entry; the router redirect also reacts to the cleared session.
/// * Plan / lease / warnings targets are built by later epics — until then they
///   show a "coming soon" snackbar rather than navigating to a missing route.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key, required this.role});

  /// Builds the More screen for [role], adapting the visible rows. Used by the
  /// role shells so each shell's More tab renders the right list.
  const MoreScreen.forRole(this.role, {super.key});

  /// The shell role this More menu belongs to. Tenants get a simpler list.
  final Role role;

  bool get _isLandlordLike =>
      role == Role.landlord || role == Role.manager;

  Future<void> _toggleLanguage(WidgetRef ref) =>
      ref.read(localeProvider.notifier).toggle();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    // Explicit nav so logout feels immediate even though the router redirect
    // also reacts to the now-unauthenticated session.
    context.go(PhoneEntryScreen.routePath);
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(
      authControllerProvider.select((s) => s.valueOrNull?.user),
    );

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.more_title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s5,
            KhatirSpacing.s2,
            KhatirSpacing.s5,
            KhatirSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(user: user, l10n: l10n),
              const SizedBox(height: KhatirSpacing.s3),
              _RowsCard(
                rows: _buildRows(context, ref, l10n),
              ),
              const SizedBox(height: KhatirSpacing.s4),
              _LogoutButton(
                label: l10n.more_logout,
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Assembles the row list for the current role. Tenants omit the landlord-
  /// only rows (AI lease, warnings) per the design note.
  List<MoreRow> _buildRows(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final rows = <_RowSpec>[
      _RowSpec(
        icon: Icons.person_outline,
        titleBn: l10n.more_profile,
        titleEn: l10n.more_profile_en,
        onTap: () => _comingSoon(context, l10n.more_profile),
      ),
      _RowSpec(
        icon: Icons.credit_card,
        titleBn: l10n.more_plan,
        titleEn: l10n.more_plan_en,
        onTap: () => _comingSoon(context, l10n.more_plan),
      ),
      if (_isLandlordLike) ...[
        _RowSpec(
          icon: Icons.description_outlined,
          titleBn: l10n.more_lease,
          titleEn: l10n.more_lease_en,
          onTap: () => _comingSoon(context, l10n.more_lease),
        ),
        _RowSpec(
          icon: Icons.flag_outlined,
          titleBn: l10n.more_warnings,
          titleEn: l10n.more_warnings_en,
          onTap: () => _comingSoon(context, l10n.more_warnings),
        ),
      ],
      _RowSpec(
        icon: Icons.language,
        titleBn: l10n.more_language,
        titleEn: l10n.more_language_en,
        onTap: () => _toggleLanguage(ref),
      ),
      _RowSpec(
        icon: Icons.group_outlined,
        titleBn: l10n.more_switch_role,
        titleEn: l10n.more_switch_role_en,
        onTap: () => context.push(RoleChooserScreen.routePath),
      ),
      _RowSpec(
        icon: Icons.auto_awesome_outlined,
        titleBn: l10n.more_about,
        titleEn: l10n.more_about_en,
        onTap: () => context.push(OnboardingScreen.routePath),
      ),
    ];

    return [
      for (var i = 0; i < rows.length; i++)
        MoreRow(
          icon: rows[i].icon,
          titleBn: rows[i].titleBn,
          titleEn: rows[i].titleEn,
          onTap: rows[i].onTap,
          showDivider: i < rows.length - 1,
        ),
    ];
  }
}

/// Plain data holder for a planned row before it is turned into a [MoreRow]
/// with the correct divider state.
class _RowSpec {
  const _RowSpec({
    required this.icon,
    required this.titleBn,
    required this.titleEn,
    required this.onTap,
  });

  final IconData icon;
  final String titleBn;
  final String titleEn;
  final VoidCallback onTap;
}

/// Sage profile header card: round avatar (first letter of name), name, masked
/// phone + role, and the plan chip (placeholder copy until EPIC-10).
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.l10n});

  final SessionUser? user;
  final AppLocalizations l10n;

  /// Masks all but the trailing digits of a phone number, e.g.
  /// `+88 01711-000111` → `+88 01711-***111`. Falls back to the raw value when
  /// it is too short to mask.
  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final visible = digits.substring(digits.length - 3);
    final masked = '*' * (digits.length - 3);
    return '$masked$visible';
  }

  String _roleLabel(Role? role) => switch (role) {
        Role.landlord => l10n.role_landlord_bn,
        Role.manager => l10n.role_manager_bn,
        Role.tenant => l10n.role_tenant_bn,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final name = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : l10n.more_name_fallback;
    final initial = name.characters.isNotEmpty
        ? name.characters.first
        : '?';
    final phone = user?.phone;
    final roleLabel = _roleLabel(user?.role);
    final subtitle = [
      if (phone != null && phone.isNotEmpty) _maskPhone(phone),
      if (roleLabel.isNotEmpty) roleLabel,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: KhatirColors.sageDk,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.titleMedium.copyWith(
                color: KhatirColors.cream,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.mutedDk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: KhatirSpacing.s2),
          // Plan chip — placeholder copy until billing lands (EPIC-10).
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s3,
              vertical: KhatirSpacing.s1,
            ),
            decoration: BoxDecoration(
              color: KhatirColors.card,
              borderRadius: BorderRadius.circular(KhatirRadius.chip),
            ),
            child: Text(
              l10n.more_plan_chip,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.sageDk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White card wrapping the action rows, clipped so the row ripples respect the
/// card radius.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows});

  final List<MoreRow> rows;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

/// Rose-tinted full-width logout button mirroring the prototype's soft
/// destructive button.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.roseBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                size: 18,
                color: KhatirColors.roseDk,
              ),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.roseDk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
