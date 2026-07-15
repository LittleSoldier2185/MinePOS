/// Tracks which authenticated users have hit the API recently, so a manager
/// can see who's actively using the system right now. Presence is inferred
/// from JWT verification — every authenticated request touches it — rather
/// than a separate heartbeat endpoint; a user counts as online if seen
/// within [onlineWithin].
class PresenceTracker {
  PresenceTracker._();
  static final instance = PresenceTracker._();

  static const onlineWithin = Duration(seconds: 30);

  // Keyed by "userId:deviceName" rather than just userId — two stations
  // signed in as the same account (e.g. two registers both logged in as
  // "cashier1") are distinct physical devices and must show up as separate
  // entries, not overwrite each other. A mid-session username rename still
  // can't orphan an entry the way keying by username alone would, since the
  // id half of the key never changes.
  final Map<String, ({int userId, String username, String role, String deviceName, DateTime seenAt})>
      _lastSeen = {};

  void touch(int id, String username, String role, String deviceName) {
    _lastSeen['$id:$deviceName'] = (
      userId: id,
      username: username,
      role: role,
      deviceName: deviceName,
      seenAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> onlineUsers() {
    final cutoff = DateTime.now().subtract(onlineWithin);
    return _lastSeen.values
        .where((v) => v.seenAt.isAfter(cutoff))
        .map((v) => {'username': v.username, 'role': v.role, 'deviceName': v.deviceName})
        .toList();
  }
}
