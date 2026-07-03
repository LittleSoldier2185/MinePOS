/// Stubbed sign-in check — no MinePOS host exists yet to hold real
/// credentials (bcrypt hashing + JWT issuance are server-side work).
/// Swap the body of [login] for a real HTTP call once the host exists; the
/// caller already handles both outcomes so the UI won't need to change.
class AuthService {
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return username.trim().isNotEmpty && password.isNotEmpty;
  }
}
