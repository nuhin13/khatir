import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Add-tenant method chooser, mirroring the `addTenant` prototype
/// (`proto/screens-landlord2.js` → `reg('addTenant')`).
///
/// The entry point for onboarding a tenant: pick how to capture their details.
/// Composition, top to bottom:
/// * **Top bar** — the bilingual "Add tenant" title with a back action.
/// * **Emoji hero** — a 👋 greeting and a "how would you like to start?" prompt.
/// * **Method cards** — three tappable cards:
///   * **OCR** (starred/sage-bordered hero) → snap the NID, AI fills everything.
///   * **Voice** → say it in Bangla. Hidden when the `voice_tenant_entry`
///     feature flag is off (read from `/config/public`).
///   * **Manual** → fill it in yourself.
///   Each routes to `/tenants/add/{ocr|voice|manual}` carrying the optional
///   target [unitId] so the downstream flow knows which unit it is onboarding
///   into. Launched from the home FAB there is no unit yet (see §15 of the
///   task); the downstream flow lets the user pick/confirm the unit on save.
/// * **Tip card** — the sage "NID photo is fastest" hint.
///
/// All colors/spacing/radii come from the design tokens.
class AddTenantScreen extends ConsumerWidget {
  const AddTenantScreen({super.key, this.unitId});

  /// Optional target unit id, passed through from a unit-scoped entry point
  /// (e.g. the unit-detail "Add tenant" CTA). `null` when launched from the
  /// home/portfolio FAB, where the unit is chosen later in the flow.
  final String? unitId;

  /// Top-level route (sits on the root navigator so it covers the shell).
  static const String routePath = '/tenants/add';
  static const String routeName = 'tenantsAdd';

  /// Sub-route names for the three intake methods.
  static const String ocrRouteName = 'tenantsAddOcr';
  static const String voiceRouteName = 'tenantsAddVoice';
  static const String manualRouteName = 'tenantsAddManual';

  /// Routes to a method sub-flow, carrying the target unit id (if any) as a
  /// query parameter so the deep link round-trips the unit context.
  void _goMethod(BuildContext context, String name) {
    final id = unitId;
    context.pushNamed(
      name,
      queryParameters: id == null ? const {} : {'unit': id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The voice card is flag-gated via the generic FlagsProvider. While the
    // flag resolves (or if the config fails) we fall back to the permissive
    // default (voice shown), matching the backend's "default on" behaviour.
    final voiceEnabled =
        ref.watch(flagsProvider).isEnabled('voice_tenant_entry', orElse: true);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.add_tenant_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KhatirSpacing.s5,
            KhatirSpacing.s2,
            KhatirSpacing.s5,
            KhatirSpacing.s6,
          ),
          children: [
            _EmojiHero(
              title: l10n.add_tenant_hero_title,
              subtitle: l10n.add_tenant_hero_sub,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            _MethodCard(
              key: const ValueKey('addTenantOcr'),
              emoji: '📸',
              title: l10n.add_tenant_ocr,
              subtitle: l10n.add_tenant_ocr_sub,
              starred: true,
              onTap: () => _goMethod(context, ocrRouteName),
            ),
            if (voiceEnabled) ...[
              const SizedBox(height: KhatirSpacing.s3),
              _MethodCard(
                key: const ValueKey('addTenantVoice'),
                emoji: '🎤',
                title: l10n.add_tenant_voice,
                subtitle: l10n.add_tenant_voice_sub,
                onTap: () => _goMethod(context, voiceRouteName),
              ),
            ],
            const SizedBox(height: KhatirSpacing.s3),
            _MethodCard(
              key: const ValueKey('addTenantManual'),
              emoji: '✍️',
              title: l10n.add_tenant_manual,
              subtitle: l10n.add_tenant_manual_sub,
              onTap: () => _goMethod(context, manualRouteName),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            _TipCard(text: l10n.add_tenant_tip),
          ],
        ),
      ),
    );
  }
}

/// The emoji + title + subtitle hero block at the top of the chooser.
class _EmojiHero extends StatelessWidget {
  const _EmojiHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('👋', style: TextStyle(fontSize: 40)),
        const SizedBox(height: KhatirSpacing.s2),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s1 / 2),
        Text(
          subtitle,
          style: AppTextStyles.accent.copyWith(fontSize: 22, height: 1),
        ),
      ],
    );
  }
}

/// A single tappable method card: emoji badge, bilingual title + subtitle, and
/// a trailing star (recommended) or chevron. The starred OCR card gets a sage
/// border, tinted background, and a gradient badge, matching the prototype's
/// emphasis on the fastest path.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.starred = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.card);
    final badge = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: starred
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KhatirColors.sage, KhatirColors.sageDk],
              )
            : null,
        color: starred ? null : KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: starred ? KhatirColors.sageBg : KhatirColors.card,
            borderRadius: radius,
            border: starred
                ? Border.all(color: KhatirColors.sage, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(KhatirSpacing.s4),
          child: Row(
            children: [
              badge,
              const SizedBox(width: KhatirSpacing.s3 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.mutedDk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KhatirSpacing.s2),
              if (starred)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s2,
                    vertical: KhatirSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: KhatirColors.sage,
                    borderRadius: BorderRadius.circular(KhatirRadius.chip),
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 12)),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: KhatirColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sage "tip" card under the method list (NID photo is the fastest path).
class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.sageDk,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
