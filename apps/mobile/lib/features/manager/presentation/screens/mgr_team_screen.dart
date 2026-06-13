import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/manager_providers.dart';
import '../../data/models/manager_models.dart';

/// Manager team screen (EPIC-22 T-008).
///
/// Lists staff/sub-managers, allows adding a new member (name, phone, role,
/// optional scope), and removing members with a confirm dialog.
///
/// Route: `/manager/team`
class MgrTeamScreen extends ConsumerWidget {
  const MgrTeamScreen({super.key});

  static const routePath = 'team';
  static const routeName = 'managerTeam';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teamAsync = ref.watch(managerTeamProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        title: Text(
          l10n.mgr_team_title,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: KhatirSpacing.s3),
            child: TextButton.icon(
              onPressed: () => _showAddMemberSheet(context, ref, l10n),
              icon: Icon(Icons.add, color: KhatirColors.sage, size: 18),
              label: Text(
                l10n.mgr_team_add,
                style: TextStyle(
                  color: KhatirColors.sage,
                  fontFamily: KhatirFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.toString(),
                style: TextStyle(color: KhatirColors.danger),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KhatirColors.sage,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.button),
                  ),
                ),
                onPressed: () => ref.invalidate(managerTeamProvider),
                child: Text(l10n.common_retry),
              ),
            ],
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyState(l10n: l10n, onAdd: () {
              _showAddMemberSheet(context, ref, l10n);
            });
          }
          return RefreshIndicator(
            color: KhatirColors.sage,
            onRefresh: () => ref.read(managerTeamProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(KhatirSpacing.s4),
              itemCount: members.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KhatirSpacing.s3),
              itemBuilder: (context, index) => _MemberCard(
                member: members[index],
                l10n: l10n,
                onRemove: () =>
                    _confirmRemove(context, ref, members[index], l10n),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.mgr_team_remove_confirm_title,
          style: TextStyle(fontFamily: KhatirFonts.title),
        ),
        content: Text(
          l10n.mgr_team_remove_confirm_body,
          style: TextStyle(fontFamily: KhatirFonts.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.mgr_team_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KhatirColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.mgr_team_confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(managerTeamProvider.notifier)
          .removeMember(member.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_team_removed),
            backgroundColor: KhatirColors.sage,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_team_remove_error),
            backgroundColor: KhatirColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showAddMemberSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KhatirColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KhatirRadius.lg),
        ),
      ),
      builder: (ctx) => _AddMemberSheet(l10n: l10n, ref: ref),
    );
  }
}

// ── Add-member bottom sheet ─────────────────────────────────────────────────

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet({required this.l10n, required this.ref});

  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = 'viewer';
  bool _submitting = false;

  static const _roles = [
    'viewer',
    'accountant',
    'assistant',
    'sub_manager',
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.ref.read(managerTeamProvider.notifier).addMember(
            phone: _phoneCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            role: _role,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.mgr_team_added),
            backgroundColor: KhatirColors.sage,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.mgr_team_add_error),
            backgroundColor: KhatirColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        MediaQuery.of(context).viewInsets.bottom + KhatirSpacing.s5,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mgr_team_add_title,
              style: TextStyle(
                color: KhatirColors.ink,
                fontFamily: KhatirFonts.title,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.mgr_team_name,
                filled: true,
                fillColor: KhatirColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.md),
                ),
              ),
              validator: (v) =>
                  (v?.trim() ?? '').isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: KhatirSpacing.s3),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.mgr_team_phone,
                hintText: '01XXXXXXXXX',
                filled: true,
                fillColor: KhatirColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.md),
                ),
              ),
              validator: (v) =>
                  (v?.trim().length ?? 0) < 10 ? 'Valid phone required' : null,
            ),
            const SizedBox(height: KhatirSpacing.s3),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(
                labelText: l10n.mgr_team_role_label,
                filled: true,
                fillColor: KhatirColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.md),
                ),
              ),
              items: _roles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r, style: TextStyle(fontFamily: KhatirFonts.body)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'viewer'),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: KhatirColors.sage,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.mgr_team_add,
                      style: TextStyle(
                        fontFamily: KhatirFonts.body,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member card ─────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.l10n,
    required this.onRemove,
  });

  final TeamMember member;
  final AppLocalizations l10n;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: KhatirColors.sageBg,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: KhatirColors.sageDk,
                fontFamily: KhatirFonts.title,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    color: KhatirColors.ink,
                    fontFamily: KhatirFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${l10n.mgr_team_role}: ${member.role}',
                  style: TextStyle(
                    color: KhatirColors.ink2,
                    fontFamily: KhatirFonts.body,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${l10n.mgr_team_scope}: '
                  '${member.scopeOwnerIds.isEmpty ? l10n.mgr_team_scope_all : member.scopeOwnerIds.length.toString()}',
                  style: TextStyle(
                    color: KhatirColors.muted,
                    fontFamily: KhatirFonts.body,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: KhatirColors.danger),
            tooltip: l10n.mgr_team_remove,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: KhatirColors.muted),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.mgr_team_empty,
              style: TextStyle(
                color: KhatirColors.ink,
                fontFamily: KhatirFonts.title,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KhatirSpacing.s5),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(
                l10n.mgr_team_add,
                style: TextStyle(
                  fontFamily: KhatirFonts.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: KhatirColors.sage,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
