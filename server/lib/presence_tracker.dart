/// Tracks which authenticated users have hit the API recently, so a manager
/// can see who's actively using the system right now. Presence is inferred
/// from JWT verification — every authenticated request touches it — rather
/// than a separate heartbeat endpoint; a user counts as online if seen
/// within [onlineWithin].
class PresenceTracker {
  PresenceTracker._();
  static final instance = PresenceTracker._();

  static const onlineWithin = Duration(seconds: 30);

  // Keyed by user id (not username) so a mid-session rename doesn't leave an
  // orphaned entry under the old username alongside a fresh one under the
  // new — same person, same key, regardless of what they're called.
  final Map<int, ({String username, String role, DateTime seenAt})> _lastSeen = {};

  void touch(int id, String username, String role) {
    _lastSeen[id] = (username: username, role: role, seenAt: DateTime.now());
  }

  List<Map<String, dynamic>> onlineUsers() {
    final cutoff = DateTime.now().subtract(onlineWithin);
    return _lastSeen.values
        .where((v) => v.seenAt.isAfter(cutoff))
        .map((v) => {'username': v.username, 'role': v.role})
        .toList();
  }
}
