/// Tracks which authenticated users have hit the API recently, so a manager
/// can see who's actively using the system right now. Presence is inferred
/// from JWT verification — every authenticated request touches it — rather
/// than a separate heartbeat endpoint; a user counts as online if seen
/// within [onlineWithin].
class PresenceTracker {
  PresenceTracker._();
  static final instance = PresenceTracker._();

  static const onlineWithin = Duration(seconds: 30);

  final Map<String, ({String role, DateTime seenAt})> _lastSeen = {};

  void touch(String username, String role) {
    _lastSeen[username] = (role: role, seenAt: DateTime.now());
  }

  List<Map<String, dynamic>> onlineUsers() {
    final cutoff = DateTime.now().subtract(onlineWithin);
    return _lastSeen.entries
        .where((e) => e.value.seenAt.isAfter(cutoff))
        .map((e) => {'username': e.key, 'role': e.value.role})
        .toList();
  }
}
