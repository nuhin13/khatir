import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/widgets/upgrade_prompt.dart';
import '../../data/lease_document_providers.dart';
import '../../data/models/lease_document.dart';
import 'lease_clause_screen.dart';
import 'lease_pdf_screen.dart';

/// Lease document screen (EPIC-18 T-006): "Smart lease — DNCC-compliant contract"
///
/// Route: `/lease/:id/document`
/// Shows the [emojiHero] 📜 "Smart lease" entry, generate-via-AI action,
/// and the resulting draft clauses with a non-dismissible disclaimer banner.
///
/// States:
///   - [_State.intro]       — fresh lease, no document yet
///   - [_State.generating]  — POST in flight
///   - [_State.draft]       — document generated, clauses shown
///   - [_State.tierGated]   — free-tier blocked (402)
///   - [_State.flagOff]     — feature flag `ai_lease_enabled` is off
///   - [_State.error]       — unexpected error
class LeaseDocumentScreen extends ConsumerStatefulWidget {
  const LeaseDocumentScreen({super.key, required this.leaseId});

  final String leaseId;

  static const String routeName = 'leaseDocument';
  static String pathFor(String leaseId) => '/lease/$leaseId/document';

  @override
  ConsumerState<LeaseDocumentScreen> createState() =>
      _LeaseDocumentScreenState();
}

enum _State { intro, generating, draft, tierGated, flagOff, error }

class _LeaseDocumentScreenState extends ConsumerState<LeaseDocumentScreen> {
  _State _uiState = _State.intro;
  LeaseDocument? _document;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Try to load an existing document on mount.
    _tryLoadExisting();
  }

  Future<void> _tryLoadExisting() async {
    try {
      final repo = ref.read(leaseDocumentRepositoryProvider);
      final doc = await repo.getDocument(widget.leaseId);
      if (mounted) {
        setState(() {
          _document = doc;
          _uiState = _State.draft;
        });
      }
    } on ApiException catch (e) {
      // 404 = no document yet — stay in intro state.
      if (e.statusCode != 404 && mounted) {
        setState(() => _uiState = _State.intro);
      }
    } catch (_) {
      // Ignore — stay in intro state.
    }
  }

  bool get _flagEnabled =>
      ref.read(flagsProvider).isEnabled('ai_lease_enabled', orElse: true);

  Future<void> _generate() async {
    if (!_flagEnabled) {
      setState(() => _uiState = _State.flagOff);
      return;
    }

    setState(() => _uiState = _State.generating);
    try {
      final repo = ref.read(leaseDocumentRepositoryProvider);
      final doc = await repo.generateDocument(widget.leaseId);
      if (mounted) {
        setState(() {
          _document = doc;
          _uiState = _State.draft;
        });
        // Keep the controller in sync.
        ref.read(leaseDocumentControllerProvider(widget.leaseId).notifier)
            .generate();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 402) {
        setState(() => _uiState = _State.tierGated);
        await UpgradePrompt.show(context);
        if (mounted) setState(() => _uiState = _State.intro);
      } else if (e.statusCode == 403) {
        setState(() => _uiState = _State.flagOff);
      } else {
        setState(() {
          _uiState = _State.error;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uiState = _State.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _back(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).go('/landlord/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('leaseDocBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _back(context),
        ),
        title: Text(
          l10n.lease_doc_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return switch (_uiState) {
      _State.intro => _IntroState(
          l10n: l10n,
          onGenerate: _generate,
        ),
      _State.generating => _GeneratingState(l10n: l10n),
      _State.draft => _DraftState(
          l10n: l10n,
          document: _document!,
          leaseId: widget.leaseId,
        ),
      _State.tierGated => _TierGatedState(l10n: l10n),
      _State.flagOff => _FlagOffState(l10n: l10n),
      _State.error => _ErrorState(
          l10n: l10n,
          message: _errorMessage,
          onRetry: _generate,
        ),
    };
  }
}

// ── Intro state ───────────────────────────────────────────────────────────────

class _IntroState extends StatelessWidget {
  const _IntroState({required this.l10n, required this.onGenerate});

  final AppLocalizations l10n;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KhatirSpacing.s6),
          // Emoji hero
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: KhatirColors.sageBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '📜',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s4),
          Text(
            l10n.lease_doc_title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            l10n.lease_doc_subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: KhatirColors.mutedDk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s6),
          FilledButton.icon(
            key: const ValueKey('leaseDocGenerate'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(l10n.lease_generate),
            onPressed: onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: KhatirColors.sage,
              foregroundColor: KhatirColors.cream,
              padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
              textStyle: AppTextStyles.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KhatirRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generating state ──────────────────────────────────────────────────────────

class _GeneratingState extends StatelessWidget {
  const _GeneratingState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              key: ValueKey('leaseDocGenerating'),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.lease_draft_generating,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draft state ───────────────────────────────────────────────────────────────

class _DraftState extends StatelessWidget {
  const _DraftState({
    required this.l10n,
    required this.document,
    required this.leaseId,
  });

  final AppLocalizations l10n;
  final LeaseDocument document;
  final String leaseId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(KhatirSpacing.s4),
            children: [
              // Disclaimer banner — always visible, non-dismissible.
              _DisclaimerBanner(l10n: l10n, disclaimer: document.disclaimer),
              const SizedBox(height: KhatirSpacing.s4),
              // Clause count
              Text(
                l10n.lease_draft_clauses(document.clauses.length),
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.mutedDk,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              // Clause list preview
              ...document.clauses.take(3).map(
                    (clause) => _ClausePreviewTile(clause: clause, l10n: l10n),
                  ),
              if (document.clauses.length > 3) ...[
                const SizedBox(height: KhatirSpacing.s2),
                Text(
                  '+ ${document.clauses.length - 3} more clauses',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Footer actions
        _DraftFooter(l10n: l10n, leaseId: leaseId),
      ],
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.l10n, required this.disclaimer});

  final AppLocalizations l10n;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leaseDisclaimer'),
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.md),
        border: Border.all(color: KhatirColors.butterDk.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: KhatirColors.butterDk,
            size: 18,
          ),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Text(
              disclaimer.isNotEmpty ? disclaimer : l10n.lease_disclaimer,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.butterDk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClausePreviewTile extends StatelessWidget {
  const _ClausePreviewTile({required this.clause, required this.l10n});

  final LeaseDocumentClause clause;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KhatirSpacing.s2),
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clause.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (clause.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: KhatirColors.sageBg,
                    borderRadius: BorderRadius.circular(KhatirRadius.chip),
                  ),
                  child: Text(
                    l10n.lease_clause_required,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.sageDk,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            clause.content,
            style:
                AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DraftFooter extends StatelessWidget {
  const _DraftFooter({required this.l10n, required this.leaseId});

  final AppLocalizations l10n;
  final String leaseId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KhatirColors.card,
        border: Border(top: BorderSide(color: KhatirColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('leaseDocEditClauses'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.lease_edit_clauses),
                onPressed: () => GoRouter.of(context).push(
                  LeaseClauseScreen.pathFor(leaseId),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: KhatirColors.sage,
                  foregroundColor: KhatirColors.cream,
                  padding:
                      const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
                  textStyle: AppTextStyles.labelLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.button),
                  ),
                ),
              ),
            ),
            const SizedBox(width: KhatirSpacing.s3),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('leaseDocViewPdf'),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(l10n.lease_view_pdf),
                onPressed: () => GoRouter.of(context).push(
                  LeasePdfScreen.pathFor(leaseId),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KhatirColors.sageDk,
                  backgroundColor: KhatirColors.sageBg,
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
                  textStyle: AppTextStyles.labelLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tier-gated state ──────────────────────────────────────────────────────────

class _TierGatedState extends StatelessWidget {
  const _TierGatedState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('leaseDocTierGated'),
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: KhatirColors.butterDk,
            ),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.lease_tier_gated_title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.lease_tier_gated_body,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flag-off state ────────────────────────────────────────────────────────────

class _FlagOffState extends StatelessWidget {
  const _FlagOffState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('leaseDocFlagOff'),
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Text(
          l10n.lease_unavailable,
          style:
              AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.l10n,
    required this.onRetry,
    this.message,
  });

  final AppLocalizations l10n;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: KhatirColors.danger),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.lease_doc_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            OutlinedButton(
              key: const ValueKey('leaseDocRetry'),
              onPressed: onRetry,
              child: Text(l10n.lease_doc_retry),
            ),
          ],
        ),
      ),
    );
  }
}
