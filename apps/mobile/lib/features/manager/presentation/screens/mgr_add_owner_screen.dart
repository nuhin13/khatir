import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/manager_providers.dart';
import '../../data/models/manager_models.dart';

/// Manager add-owner screen (EPIC-22 T-007).
///
/// Allows a manager to link a new owner by entering their phone number.
/// Shows two sections:
/// - Pending link requests (status == `'pending'`)
/// - Active linked owners (status == `'active'`)
///
/// Route: `/manager/add-owner`
class MgrAddOwnerScreen extends ConsumerStatefulWidget {
  const MgrAddOwnerScreen({super.key});

  static const routePath = 'add-owner';
  static const routeName = 'managerAddOwner';

  @override
  ConsumerState<MgrAddOwnerScreen> createState() => _MgrAddOwnerScreenState();
}

class _MgrAddOwnerScreenState extends ConsumerState<MgrAddOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref.read(managerOwnersProvider.notifier).requestOwner(
            ownerPhone: _phoneCtrl.text.trim(),
            ownerName: _nameCtrl.text.trim(),
            permissions: const ['read_units', 'collect_rent', 'view_reports'],
          );
      if (mounted) {
        _phoneCtrl.clear();
        _nameCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_add_owner_sent),
            backgroundColor: KhatirColors.sage,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mgr_add_owner_error),
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
    final l10n = AppLocalizations.of(context);
    final ownersAsync = ref.watch(managerOwnersProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        title: Text(
          l10n.mgr_add_owner_title,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KhatirSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            _Hero(l10n: l10n),
            const SizedBox(height: KhatirSpacing.s5),

            // Link-request form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.mgr_add_owner_phone,
                      hintText: l10n.mgr_add_owner_phone_hint,
                      filled: true,
                      fillColor: KhatirColors.card,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(KhatirRadius.md),
                        borderSide: BorderSide(color: KhatirColors.line),
                      ),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.length < 10) {
                        return l10n.mgr_add_owner_err_phone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: KhatirSpacing.s3),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.mgr_add_owner_name,
                      hintText: l10n.mgr_add_owner_name_hint,
                      filled: true,
                      fillColor: KhatirColors.card,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(KhatirRadius.md),
                        borderSide: BorderSide(color: KhatirColors.line),
                      ),
                    ),
                    validator: (v) {
                      if ((v?.trim() ?? '').isEmpty) {
                        return l10n.mgr_add_owner_err_name;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: KhatirSpacing.s4),
                  FilledButton(
                    onPressed:
                        _submitting ? null : () => _submit(l10n),
                    style: FilledButton.styleFrom(
                      backgroundColor: KhatirColors.sage,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(KhatirRadius.button),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: KhatirSpacing.s3),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.mgr_add_owner_request,
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

            const SizedBox(height: KhatirSpacing.s6),

            // Owners sections
            ownersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                e.toString(),
                style: TextStyle(color: KhatirColors.danger),
              ),
              data: (owners) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OwnersSection(
                    title: l10n.mgr_add_owner_pending,
                    owners: owners
                        .where((o) => o.status == 'pending')
                        .toList(),
                    statusLabel: l10n.mgr_add_owner_status_pending,
                    statusColor: KhatirColors.butter,
                    emptyText: l10n.mgr_add_owner_none_pending,
                    l10n: l10n,
                  ),
                  const SizedBox(height: KhatirSpacing.s5),
                  _OwnersSection(
                    title: l10n.mgr_add_owner_active,
                    owners: owners
                        .where((o) => o.status == 'active')
                        .toList(),
                    statusLabel: l10n.mgr_add_owner_status_active,
                    statusColor: KhatirColors.sage,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤝',
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: KhatirSpacing.s2),
        Text(
          l10n.mgr_add_owner_hero,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          l10n.mgr_add_owner_hero_sub,
          style: TextStyle(
            color: KhatirColors.ink2,
            fontFamily: KhatirFonts.body,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _OwnersSection extends StatelessWidget {
  const _OwnersSection({
    required this.title,
    required this.owners,
    required this.statusLabel,
    required this.statusColor,
    this.emptyText,
    required this.l10n,
  });

  final String title;
  final List<LinkedOwner> owners;
  final String statusLabel;
  final Color statusColor;
  final String? emptyText;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s2),
        if (owners.isEmpty && emptyText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s2),
            child: Text(
              emptyText!,
              style: TextStyle(
                color: KhatirColors.muted,
                fontFamily: KhatirFonts.body,
                fontSize: 13,
              ),
            ),
          )
        else
          ...owners.map(
            (owner) => Padding(
              padding:
                  const EdgeInsets.only(bottom: KhatirSpacing.s2),
              child: _OwnerRow(
                owner: owner,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({
    required this.owner,
    required this.statusLabel,
    required this.statusColor,
  });

  final LinkedOwner owner;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s3),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner.ownerName,
                  style: TextStyle(
                    color: KhatirColors.ink,
                    fontFamily: KhatirFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  owner.ownerPhone,
                  style: TextStyle(
                    color: KhatirColors.ink2,
                    fontFamily: KhatirFonts.body,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(KhatirRadius.chip),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor == KhatirColors.sage
                    ? KhatirColors.sageDk
                    : KhatirColors.butterDk,
                fontFamily: KhatirFonts.body,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
