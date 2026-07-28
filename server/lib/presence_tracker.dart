/// Tracks which authenticated users have hit the API recently, so a manager
/// can see who's actively using the system right now. Presence is inferred
/// from JWT verification — every authenticated request touches it — rather
/// than a separate heartbeat endpoint; a user counts as online if seen
/// within [onlineWithin].
class PresenceTracker {
  PresenceTracker._();
  static final instance = PresenceTracker._();

  static const onlineWithin = Duration(seconds: 30);

  // Non-owner sessions expire after this much inactivity (owner sessions are
  // persistent, bounded only by the JWT's own 30-day expiry — see
  // auth_routes.dart's `_login`). A JWT's own `exp` is fixed at mint time and
  // can't reset on activity, so idle timeout has to be enforced here instead.
  static const workerIdleTimeout = Duration(minutes: 30);

  // Keyed by user+device+iat (the JWT's issue time) rather than just
  // user+device, so the first request of a brand-new login never gets
  // mistaken for a stale idle session left over from an earlier login on
  // the same device.
  // ponytail: never pruned (personal-use scale, cleared on server restart);
  // add eviction if this ever runs long enough for it to matter.
  final Map<String, DateTime> _sessionLastActive = {};

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

  bool isIdleExpired(int userId, String deviceName, int iat) {
    final last = _sessionLastActive['$userId:$deviceName:$iat'];
    if (last == null) return false;
    return DateTime.now().difference(last) > workerIdleTimeout;
  }

  void touchSession(int userId, String deviceName, int iat) {
    _sessionLastActive['$userId:$deviceName:$iat'] = DateTime.now();
  }

  List<Map<String, dynamic>> onlineUsers() {
    final cutoff = DateTime.now().subtract(onlineWithin);
    return _lastSeen.values
        .where((v) => v.seenAt.isAfter(cutoff))
        .map((v) => {'username': v.username, 'role': v.role, 'deviceName': v.deviceName})
        .toList();
  }
}
