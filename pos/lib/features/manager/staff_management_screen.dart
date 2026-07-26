import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/image_crop_screen.dart';
import '../../l10n/app_localizations.dart';
import 'models/staff_member.dart';
import 'services/staff_service.dart';

const _roles = ['owner', 'manager', 'worker'];

// "worker" is stored as-is in the DB/JWT, but reads as "Employee" everywhere
// it's shown to a human.
String _roleLabel(BuildContext context, String role) {
  final l10n = AppLocalizations.of(context)!;
  switch (role) {
    case 'worker':
      return l10n.employeeRoleDisplay;
    case 'manager':
      return l10n.managerRoleDisplay;
    case 'owner':
      return l10n.ownerRoleDisplay;
    default:
      return role;
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'owner':
      return AppColors.terracottaDark;
    case 'manager':
      return AppColors.primary;
    default:
      return AppColors.muted;
  }
}

Widget _avatar(StaffMember member, {required double radius}) {
  if (member.avatarBase64 != null) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: MemoryImage(base64Decode(member.avatarBase64!)),
    );
  }
  final initial = member.displayName;
  return CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.background,
    child: Text(
      initial.isNotEmpty ? initial[0].toUpperCase() : '?',
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}

/// Add/Edit Staff shows as a full page on phone (there's no room to float a
/// dialog over) and as a centered floating dialog on tablet/desktop, instead
/// of the bottom sheet every other form in this app uses — same underlying
/// _StaffFormBody either way, just different chrome around it.
Future<bool?> _showStaffForm(BuildContext context, {StaffMember? existing}) {
  if (Responsive.isMobile(context)) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _StaffFormScreen(existing: existing)),
    );
  }
  return showDialog<bool>(
    context: context,
    // Not dismissible by barrier tap, same reasoning as the bottom sheet's
    // isDismissible: false — an accidental tap shouldn't discard the form.
    // _StaffFormBody's own PopScope additionally blocks the back button
    // while a save is actually in flight.
    barrierDismissible: false,
    builder: (_) => _StaffFormDialog(existing: existing),
  );
}

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _svc = StaffService.instance;
  late Future<List<StaffMember>> _future;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetchAll();
    AppSettingsService.instance.getStaffGridView().then((v) {
      if (mounted) setState(() => _isGridView = v);
    });
  }

  void _reload() => setState(() {
    _future = _svc.fetchAll();
  });

  void _setGridView(bool value) {
    setState(() => _isGridView = value);
    AppSettingsService.instance.setStaffGridView(value);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: AppColors.terracottaDark),
    );
  }

  Future<void> _showAddStaffForm() async {
    final created = await _showStaffForm(context);
    if (created == true) _reload();
  }

  Future<void> _showEditStaffForm(StaffMember m) async {
    final saved = await _showStaffForm(context, existing: m);
    if (saved == true) _reload();
  }

  void _showStaffDetail(StaffMember m) {
    showDialog(
      context: context,
      builder: (_) => _StaffDetailDialog(member: m),
    );
  }

  Future<void> _toggleActive(StaffMember m) async {
    try {
      await _svc.setActive(m.id, !m.active);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _forceLogout(StaffMember m) async {
    try {
      await _svc.forceLogout(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.signedOutSnackbar(m.username),
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete(StaffMember m) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeStaffTitle),
        content: Text(l10n.removeStaffContent(m.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.remove,
              style: const TextStyle(color: AppColors.terracottaDark),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.delete(m.id);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagementTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? l10n.listViewTooltip : l10n.gridViewTooltip,
            onPressed: () => _setGridView(!_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: l10n.addStaffTooltip,
            onPressed: _showAddStaffForm,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<StaffMember>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 32,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: Text(l10n.retry)),
                  ],
                ),
              ),
            );
          }
          final staff = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: _isGridView
                // Cards are wide horizontal rows now, not small square tiles,
                // so a max-extent delegate (1 column on phone width, more as
                // space allows) fits better than a fixed column count.
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    // CR80 ID card ratio (~85.6mm x 53.98mm, the size of a
                    // real driver's license/badge) instead of an arbitrary
                    // rectangle, per the card-view redesign.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          childAspectRatio: 1.586,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: staff.length,
                    itemBuilder: (_, i) => _StaffGridCard(
                      member: staff[i],
                      isSelf: staff[i].id == ServerClient.instance.userId,
                      onEdit: () => _showEditStaffForm(staff[i]),
                      onToggleActive: () => _toggleActive(staff[i]),
                      onForceLogout: () => _forceLogout(staff[i]),
                      onDelete: () => _confirmDelete(staff[i]),
                      onViewDetail: () => _showStaffDetail(staff[i]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: staff.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _StaffRow(
                      member: staff[i],
                      isSelf: staff[i].id == ServerClient.instance.userId,
                      onEdit: () => _showEditStaffForm(staff[i]),
                      onToggleActive: () => _toggleActive(staff[i]),
                      onForceLogout: () => _forceLogout(staff[i]),
                      onDelete: () => _confirmDelete(staff[i]),
                      onViewDetail: () => _showStaffDetail(staff[i]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// ── Staff row card (list view) ───────────────────────────────────────────────

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.member,
    required this.isSelf,
    required this.onEdit,
    required this.onToggleActive,
    required this.onForceLogout,
    required this.onDelete,
    required this.onViewDetail,
  });
  final StaffMember member;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onForceLogout;
  final VoidCallback onDelete;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: member.active ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onViewDetail,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    _avatar(member, radius: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.youLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (member.name != null && member.name!.isNotEmpty)
                            Text(
                              '@${member.username}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _roleColor(
                                member.role,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _roleLabel(context, member.role).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: _roleColor(member.role),
                              ),
                            ),
                          ),
                          if (member.email != null || member.phone != null) ...[
                            const SizedBox(height: 4),
                            if (member.email != null)
                              Text(
                                member.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            if (member.phone != null)
                              Text(
                                member.phone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: AppLocalizations.of(context)!.editStaffTooltip,
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              color: AppColors.muted,
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 18),
              tooltip: AppLocalizations.of(context)!.forceSignoutTooltip,
              onPressed: onForceLogout,
              visualDensity: VisualDensity.compact,
              color: AppColors.muted,
            ),
            Switch(
              value: member.active,
              onChanged: isSelf ? null : (_) => onToggleActive(),
              activeThumbColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: isSelf ? null : onDelete,
              visualDensity: VisualDensity.compact,
              color: isSelf
                  ? AppColors.muted.withValues(alpha: 0.4)
                  : AppColors.terracottaDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff grid card ───────────────────────────────────────────────────────────

class _StaffGridCard extends StatelessWidget {
  const _StaffGridCard({
    required this.member,
    required this.isSelf,
    required this.onEdit,
    required this.onToggleActive,
    required this.onForceLogout,
    required this.onDelete,
    required this.onViewDetail,
  });
  final StaffMember member;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onForceLogout;
  final VoidCallback onDelete;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactLine = member.email ?? member.phone;
    return Opacity(
      opacity: member.active ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracottaLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onViewDetail,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _avatar(member, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isSelf) ...[
                              const SizedBox(width: 6),
                              Text(
                                l10n.youLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Discord-style stacked subtitle: @handle, then a
                        // contact line underneath, like a status line.
                        if (member.name != null && member.name!.isNotEmpty)
                          Text(
                            '@${member.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        if (contactLine != null)
                          Text(
                            contactLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor(member.role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _roleLabel(context, member.role).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: _roleColor(member.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: l10n.editStaffTooltip,
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.muted,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  tooltip: l10n.forceSignoutTooltip,
                  onPressed: onForceLogout,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.muted,
                ),
                Switch(
                  value: member.active,
                  onChanged: isSelf ? null : (_) => onToggleActive(),
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: isSelf ? null : onDelete,
                  visualDensity: VisualDensity.compact,
                  color: isSelf
                      ? AppColors.muted.withValues(alpha: 0.4)
                      : AppColors.terracottaDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff detail dialog (read-only — join date + tenure) ────────────────────

class _StaffDetailDialog extends StatelessWidget {
  const _StaffDetailDialog({required this.member});
  final StaffMember member;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Whichever unit is most meaningful: days under a month, months under a
  /// year, otherwise years (plus a leftover-months remainder, e.g. "2 years
  /// 3 months") — computed from calendar months so it accounts for
  /// different month lengths rather than a naive `Duration ~/ 30`.
  String _tenure(AppLocalizations l10n, DateTime since) {
    final now = DateTime.now();
    var months = (now.year - since.year) * 12 + (now.month - since.month);
    if (now.day < since.day) months -= 1;
    if (months < 1) {
      final days = now.difference(since).inDays;
      return l10n.tenureDaysLabel(days < 0 ? 0 : days);
    }
    final years = months ~/ 12;
    final remainderMonths = months % 12;
    if (years < 1) return l10n.tenureMonthsLabel(months);
    return remainderMonths == 0
        ? l10n.tenureYearsLabel(years)
        : '${l10n.tenureYearsLabel(years)} ${l10n.tenureMonthsLabel(remainderMonths)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Center(child: _avatar(member, radius: 36)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                '@${member.username}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor(member.role).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _roleLabel(context, member.role).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _roleColor(member.role),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _StaffDetailRow(
              label: l10n.staffJoinedLabel,
              value: _formatDate(member.createdAt),
            ),
            const SizedBox(height: 8),
            _StaffDetailRow(
              label: l10n.staffTenureLabel,
              value: _tenure(l10n, member.createdAt),
            ),
            if (member.email != null) ...[
              const SizedBox(height: 8),
              _StaffDetailRow(
                label: l10n.emailFieldLabel,
                value: member.email!,
              ),
            ],
            if (member.phone != null) ...[
              const SizedBox(height: 8),
              _StaffDetailRow(
                label: l10n.phoneFieldLabel,
                value: member.phone!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffDetailRow extends StatelessWidget {
  const _StaffDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Add / edit staff: full-page (phone) / floating dialog (tablet+desktop) ──

/// Full-page version, pushed via Navigator on phone — no room to float a
/// dialog over a small screen.
class _StaffFormScreen extends StatelessWidget {
  const _StaffFormScreen({this.existing});
  final StaffMember? existing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          existing == null ? l10n.addStaffLabel : l10n.editStaffLabel,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _StaffFormBody(existing: existing),
        ),
      ),
    );
  }
}

/// Centered floating dialog version, used on tablet/desktop where there's
/// enough screen to spare — a full-page push would feel heavy-handed there.
class _StaffFormDialog extends StatelessWidget {
  const _StaffFormDialog({this.existing});
  final StaffMember? existing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? l10n.addStaffLabel : l10n.editStaffLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _StaffFormBody(existing: existing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffFormBody extends StatefulWidget {
  const _StaffFormBody({this.existing});

  /// Null means "add staff"; non-null means "edit" (password optional).
  final StaffMember? existing;

  @override
  State<_StaffFormBody> createState() => _StaffFormBodyState();
}

class _StaffFormBodyState extends State<_StaffFormBody> {
  bool get _isEdit => widget.existing != null;
  bool get _isSelfEdit =>
      _isEdit && widget.existing!.id == ServerClient.instance.userId;
  bool get _usernameChanged =>
      _isEdit && _usernameCtrl.text.trim() != widget.existing!.username;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  late String _role = widget.existing?.role ?? 'worker';
  String? _avatarBase64;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl.text = e?.name ?? '';
    _usernameCtrl.text = e?.username ?? '';
    _emailCtrl.text = e?.email ?? '';
    _phoneCtrl.text = e?.phone ?? '';
    _avatarBase64 = e?.avatarBase64;
    // Renaming requires the confirm-password field to appear/disappear, so
    // the form needs to react to every keystroke here, not just on submit.
    _usernameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => ImageCropScreen(imageBytes: bytes)),
    );
    if (cropped == null) return;
    setState(() => _avatarBase64 = base64Encode(cropped));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    try {
      if (_isEdit) {
        await StaffService.instance.update(
          widget.existing!.id,
          role: _role,
          password: _passwordCtrl.text,
          name: name,
          email: email,
          phone: phone,
          avatarBase64: _avatarBase64,
          username: _usernameChanged ? _usernameCtrl.text.trim() : null,
          confirmPassword: _usernameChanged ? _confirmPasswordCtrl.text : null,
        );
      } else {
        await StaffService.instance.create(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
          name: name,
          email: email,
          phone: phone,
          avatarBase64: _avatarBase64,
        );
      }
      // Editing your own profile changes what the sidebar/app-bar user card
      // shows (name, avatar) — update the already-known values in place
      // rather than waiting for the next login to pick them up.
      if (_isSelfEdit) {
        ServerClient.instance.updateOwnProfile(
          name: name.isEmpty ? null : name,
          avatarBase64: _avatarBase64,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Blocks the back button while a save is in flight, so it can't be used
    // to slip past the disabled Cancel/Save buttons — the wrapping screen's
    // AppBar back arrow goes through the same Navigator pop path, and the
    // dialog's barrier tap is already closed off via barrierDismissible:
    // false where it's shown (_showStaffForm).
    return PopScope(
      canPop: !_saving,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    ClipOval(
                      child: _avatarBase64 != null
                          ? Image.memory(
                              base64Decode(_avatarBase64!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: AppColors.background,
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.muted,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.staffNameLabel,
                hintText: l10n.staffNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: l10n.usernameLabel,
                hintText: l10n.usernameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.usernameRequiredValidator
                  : null,
            ),
            if (_usernameChanged) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmYourPasswordLabel,
                  hintText: l10n.confirmYourPasswordHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.confirmYourPasswordRequiredValidator
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.staffPasswordLabel,
                hintText: _isEdit
                    ? l10n.staffPasswordEditHint
                    : l10n.staffPasswordHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (_isEdit && (v == null || v.isEmpty))
                  ? null
                  : (v == null || v.length < 8)
                  ? l10n.staffPasswordTooShort
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailFieldLabel,
                hintText: l10n.emailFieldHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return v.contains('@') ? null : l10n.emailInvalidValidatorError;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneFieldLabel,
                hintText: l10n.phoneFieldHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.roleLabel,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _roles.map((r) {
                final sel = _role == r;
                return ChoiceChip(
                  label: Text(
                    _roleLabel(context, r),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: sel,
                  onSelected: _isSelfEdit
                      ? null
                      : (_) => setState(() => _role = r),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: sel ? AppColors.accent : AppColors.ink,
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.terracottaDark,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : Text(_isEdit ? l10n.saveChanges : l10n.addStaffLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
