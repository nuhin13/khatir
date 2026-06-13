import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/lease_document_providers.dart';
import '../../data/models/lease_document.dart';

/// Clause review and edit screen (EPIC-18 T-007).
///
/// Route: `/lease/:id/clauses`
///
/// Displays the full list of AI-generated clauses for a lease document.
/// Each clause is shown as an editable text area. Required clauses display a
/// lock icon and cannot be deleted — only their text content can be edited.
/// Optional clauses can be deleted by the landlord.
///
/// On "Save", a PATCH request is sent via [LeaseDocumentController.updateClauses].
class LeaseClauseScreen extends ConsumerStatefulWidget {
  const LeaseClauseScreen({super.key, required this.leaseId});

  final String leaseId;

  static const String routeName = 'leaseClause';
  static String pathFor(String leaseId) => '/lease/$leaseId/clauses';

  @override
  ConsumerState<LeaseClauseScreen> createState() => _LeaseClauseScreenState();
}

class _LeaseClauseScreenState extends ConsumerState<LeaseClauseScreen> {
  /// Working copy of the clause list. Initialised from the provider on first
  /// build; edits are kept in local state and flushed on Save.
  List<LeaseDocumentClause>? _clauses;

  /// Text controllers for each clause, keyed by clause id.
  final Map<String, TextEditingController> _controllers = {};

  bool _saving = false;

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initClauses(List<LeaseDocumentClause> clauses) {
    if (_clauses != null) return; // already initialised
    _clauses = List.of(clauses);
    for (final clause in _clauses!) {
      _controllers[clause.id] = TextEditingController(text: clause.content);
    }
  }

  /// Rebuilds the working list from the current text-controller values and
  /// sends the PATCH request.
  Future<void> _save(AppLocalizations l10n) async {
    if (_clauses == null) return;
    setState(() => _saving = true);
    try {
      final updated = _clauses!.map((clause) {
        final text = _controllers[clause.id]?.text ?? clause.content;
        return clause.copyWith(content: text);
      }).toList(growable: false);

      await ref
          .read(leaseDocumentControllerProvider(widget.leaseId).notifier)
          .updateClauses(updated);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.lease_clause_saved)));
        // Return to caller; they will see the updated document in the provider.
        if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.lease_clause_save_error)),
          );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _deleteClause(String clauseId) {
    setState(() {
      _clauses!.removeWhere((c) => c.id == clauseId);
      _controllers.remove(clauseId)?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final docAsync =
        ref.watch(leaseDocumentControllerProvider(widget.leaseId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        key: const ValueKey('leaseClauseAppBar'),
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('leaseClauseBack'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
          },
        ),
        title: Text(
          l10n.lease_clause_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: KhatirSpacing.s4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              key: const ValueKey('leaseClauseSave'),
              onPressed: () => _save(l10n),
              child: Text(
                l10n.lease_clause_save,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.sage,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: docAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              l10n.lease_doc_error,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
              textAlign: TextAlign.center,
            ),
          ),
          data: (doc) {
            _initClauses(doc.clauses);
            return _ClauseList(
              clauses: _clauses ?? doc.clauses,
              controllers: _controllers,
              onDelete: _deleteClause,
              l10n: l10n,
            );
          },
        ),
      ),
    );
  }
}

// ── Clause list ───────────────────────────────────────────────────────────────

class _ClauseList extends StatelessWidget {
  const _ClauseList({
    required this.clauses,
    required this.controllers,
    required this.onDelete,
    required this.l10n,
  });

  final List<LeaseDocumentClause> clauses;
  final Map<String, TextEditingController> controllers;
  final void Function(String clauseId) onDelete;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (clauses.isEmpty) {
      return Center(
        child: Text(
          l10n.lease_doc_error,
          style:
              AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s4,
      ),
      itemCount: clauses.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: KhatirSpacing.s4),
      itemBuilder: (context, index) {
        final clause = clauses[index];
        return _ClauseTile(
          key: ValueKey('leaseClause_${clause.id}'),
          clause: clause,
          controller: controllers[clause.id] ??
              TextEditingController(text: clause.content),
          onDelete: clause.isRequired ? null : () => onDelete(clause.id),
          l10n: l10n,
        );
      },
    );
  }
}

// ── Individual clause tile ────────────────────────────────────────────────────

class _ClauseTile extends StatelessWidget {
  const _ClauseTile({
    super.key,
    required this.clause,
    required this.controller,
    required this.l10n,
    this.onDelete,
  });

  final LeaseDocumentClause clause;
  final TextEditingController controller;
  final AppLocalizations l10n;

  /// Null when the clause is required (no delete allowed).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KhatirSpacing.s4,
              KhatirSpacing.s3,
              KhatirSpacing.s2,
              KhatirSpacing.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    clause.title.isNotEmpty
                        ? clause.title
                        : 'Clause ${clause.sortOrder}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (clause.isRequired) ...[
                  Tooltip(
                    message: l10n.lease_clause_required_lock,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KhatirSpacing.s2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KhatirColors.sageBg,
                        borderRadius: BorderRadius.circular(KhatirRadius.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: KhatirColors.sageDk,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l10n.lease_clause_required,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: KhatirColors.sageDk,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (onDelete != null) ...[
                  IconButton(
                    key: ValueKey('deleteClause_${clause.id}'),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: KhatirColors.danger,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete clause',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: KhatirColors.line),
          // ── Editable content ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s4),
            child: TextField(
              key: ValueKey('clauseField_${clause.id}'),
              controller: controller,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.ink,
              ),
              decoration: InputDecoration(
                hintText: l10n.lease_clause_edit_hint,
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: KhatirColors.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
