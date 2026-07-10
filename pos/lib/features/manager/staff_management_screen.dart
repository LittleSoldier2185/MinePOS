import 'package:flutter/material.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import 'models/staff_member.dart';
import 'services/staff_service.dart';

const _roles = ['owner', 'manager', 'worker'];

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _svc = StaffService.instance;
  late Future<List<StaffMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetchAll();
  }

  void _reload() => setState(() => _future = _svc.fetchAll());

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: AppColors.terracottaDark),
    );
  }

  Future<void> _showAddStaffForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StaffFormSheet(),
    );
    if (created == true) _reload();
  }

  Future<void> _toggleActive(StaffMember m) async {
    try {
      await _svc.setActive(m.username, !m.active);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _forceLogout(StaffMember m) async {
    try {
      await _svc.forceLogout(m.username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${m.username}" signed out on all devices')),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete(StaffMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Staff?'),
        content: Text(
            'Permanently remove "${m.username}" from the system? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.delete(m.username);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: 'Add staff',
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
                    const Icon(Icons.error_outline,
                        size: 32, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final staff = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: staff.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _StaffRow(
                member: staff[i],
                isSelf: staff[i].username == ServerClient.instance.username,
                onToggleActive: () => _toggleActive(staff[i]),
                onForceLogout: () => _forceLogout(staff[i]),
                onDelete: () => _confirmDelete(staff[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Staff row card ──────────────────────────────────────────────────────────

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.member,
    required this.isSelf,
    required this.onToggleActive,
    required this.onForceLogout,
    required this.onDelete,
  });
  final StaffMember member;
  final bool isSelf;
  final VoidCallback onToggleActive;
  final VoidCallback onForceLogout;
  final VoidCallback onDelete;

  Color _roleColor() {
    switch (member.role) {
      case 'owner':
        return AppColors.terracottaDark;
      case 'manager':
        return AppColors.primary;
      default:
        return AppColors.muted;
    }
  }

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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.background,
              child: Text(
                member.username.isNotEmpty
                    ? member.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.username,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        const Text('(you)',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _roleColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      member.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: _roleColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 18),
              tooltip: 'Force sign-out',
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
              color: isSelf ? AppColors.muted.withValues(alpha: 0.4) : AppColors.terracottaDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add staff bottom sheet ──────────────────────────────────────────────────

class _StaffFormSheet extends StatefulWidget {
  const _StaffFormSheet();

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'worker';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await StaffService.instance.create(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
      );
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add Staff',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. jane',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Temporary password',
                hintText: 'At least 8 characters',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Password must be at least 8 characters'
                  : null,
            ),
            const SizedBox(height: 14),
            const Text('Role',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _roles.map((r) {
                final sel = _role == r;
                return ChoiceChip(
                  label: Text(r, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  onSelected: (_) => setState(() => _role = r),
                  selectedColor: AppColors.primary,
                  labelStyle:
                      TextStyle(color: sel ? AppColors.accent : AppColors.ink),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
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
                                strokeWidth: 2, color: AppColors.accent),
                          )
                        : const Text('Add Staff'),
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
