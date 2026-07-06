/// Stubbed password-reset flow.
/// All three methods always succeed on valid inputs.
/// Replace each with a real HTTP call once the backend exists;
/// the callers already handle both outcomes so the UI won't change.
class PasswordResetService {
  Future<bool> requestOtp(String username) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return username.trim().isNotEmpty;
  }

  Future<bool> verifyOtp(String username, String otp) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return otp.length == 6;
  }

  Future<bool> resetPassword(
    String username,
    String otp,
    String newPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return newPassword.length >= 8;
  }
}
