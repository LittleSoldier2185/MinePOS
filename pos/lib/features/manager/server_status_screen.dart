import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/services/local_server_launcher.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../connect/services/connection_service.dart';

/// Status + controls for the local server this Windows device is hosting.
/// Only meaningful here — a client connected to someone else's host has no
/// filesystem access to that machine's log file, and no business restarting
/// a server other devices depend on.
class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  final _svc = ConnectionService();
  bool? _running;
  Timer? _timer;
  bool _restarting = false;

  List<Map<String, dynamic>> _onlineUsers = [];
  int _kitchenDisplays = 0;
  int _customerDisplays = 0;

  @override
  void initState() {
    super.initState();
    _check();
    _loadPresence();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _check();
      _loadPresence();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final address = ServerClient.instance.baseUrl;
    final ok = address != null && await _svc.testConnection(address);
    if (mounted) setState(() => _running = ok);
  }

  Future<void> _loadPresence() async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final res = await http
          .get(client.uri('/admin/presence'), headers: client.headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _onlineUsers =
              (data['onlineUsers'] as List).cast<Map<String, dynamic>>();
          _kitchenDisplays = data['kitchenDisplays'] as int;
          _customerDisplays = data['customerDisplays'] as int;
        });
      }
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() => _restarting = true);
    final ok = await LocalServerLauncher.instance.ensureRunning();
    if (!mounted) return;
    setState(() => _restarting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.startServerFailedMessage)),
      );
    }
    _check();
  }

  Future<void> _restart() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.restartServerTitle),
        content: Text(l10n.restartServerContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restartServerButton,
                style: const TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _restarting = true);
    final client = ServerClient.instance;
    try {
      await http
          .post(client.uri('/admin/restart'), headers: client.headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    // Wait for the process to actually exit, then let the launcher bring a
    // fresh one back up (no-op success if it's already back by the time we
    // check).
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline) &&
        await _svc.testConnection(client.baseUrl!)) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final relaunched = await LocalServerLauncher.instance.ensureRunning();

    if (!mounted) return;
    setState(() => _restarting = false);
    if (!relaunched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.restartServerFailedMessage)),
      );
    }
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (_running) {
      true => (Colors.green.shade700, l10n.serverStatusRunningLabel),
      false => (AppColors.terracottaDark, l10n.serverStatusStoppedLabel),
      null => (AppColors.muted, l10n.connectingLabel),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverSectionLabel),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.terracottaLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _running == true
                          ? OutlinedButton.icon(
                              onPressed: _restarting ? null : _restart,
                              icon: _restarting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.restart_alt, size: 16),
                              label: Text(_restarting
                                  ? l10n.restartingServerMessage
                                  : l10n.restartServerButton),
                            )
                          : OutlinedButton.icon(
                              onPressed: _restarting ? null : _start,
                              icon: _restarting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.play_arrow, size: 16),
                              label: Text(_restarting
                                  ? l10n.startingServerMessage
                                  : l10n.startServerButton),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ServerLogsScreen()),
                        ),
                        icon: const Icon(Icons.article_outlined, size: 16),
                        label: Text(l10n.viewLogsButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.terracottaLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.liveActivityTitle,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.people_outline,
                        label: l10n.usersOnlineLabel,
                        count: _onlineUsers.length,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.soup_kitchen_outlined,
                        label: l10n.kitchenDisplaysLabel,
                        count: _kitchenDisplays,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.tv_outlined,
                        label: l10n.customerDisplaysLabel,
                        count: _customerDisplays,
                      ),
                    ),
                  ],
                ),
                if (_onlineUsers.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  ..._onlineUsers.map(
                    (u) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 8, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(u['username'] as String,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Text('(${u['role']})',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
                          if ((u['deviceName'] as String?)?.isNotEmpty ?? false) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('· ${u['deviceName']}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.muted)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(l10n.noUsersOnlineMessage,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.count});
  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text('$count',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
              maxLines: 2),
        ],
      ),
    );
  }
}

// ── Log viewer ───────────────────────────────────────────────────────────────

class ServerLogsScreen extends StatefulWidget {
  const ServerLogsScreen({super.key});

  @override
  State<ServerLogsScreen> createState() => _ServerLogsScreenState();
}

class _ServerLogsScreenState extends State<ServerLogsScreen> {
  static const _maxLines = 300;

  Timer? _timer;
  String? _content;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final file = LocalServerLauncher.instance.logFile;
    if (file == null || !await file.exists()) {
      if (mounted) setState(() => _content = '');
      return;
    }
    final lines = (await file.readAsString()).split('\n');
    final tail =
        lines.length > _maxLines ? lines.sublist(lines.length - _maxLines) : lines;
    if (mounted) setState(() => _content = tail.join('\n'));
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _content ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.logsCopiedSnackbar)),
    );
  }

  Future<void> _openFolder() async {
    final file = LocalServerLauncher.instance.logFile;
    if (file == null) return;
    await Process.run('explorer', ['/select,${file.path}']);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasContent = (_content ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverLogsTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: l10n.openLogFolderButton,
            onPressed: hasContent ? _openFolder : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: l10n.copyLogsButton,
            onPressed: hasContent ? _copy : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: _load,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _content == null
          ? const Center(child: CircularProgressIndicator())
          : hasContent
              ? SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _content!,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.ink),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.serverLogsEmptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
    );
  }
}
