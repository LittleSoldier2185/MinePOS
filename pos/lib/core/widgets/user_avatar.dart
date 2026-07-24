import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small badge at an avatar's bottom-right corner (classic Discord desktop
/// look) vs. a full colored ring around the whole avatar (used on the phone
/// app bar, where there's no room for a name/tag next to it to give context).
enum UserAvatarStatusStyle { dot, ring }

/// Circular profile avatar for the signed-in user, decorated with an
/// online-status indicator. Falls back to an initial-letter avatar when no
/// [avatarBase64] is set — same convention as Staff Management's own avatar
/// rendering (`staff_management_screen.dart`'s private `_avatar` helper),
/// just shared here since this is now used outside that screen too.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarBase64,
    required this.displayName,
    this.radius = 18,
    this.style = UserAvatarStatusStyle.dot,
    this.badgeBorderColor = Colors.white,
  });

  final String? avatarBase64;
  final String displayName;
  final double radius;
  final UserAvatarStatusStyle style;

  /// The badge/ring needs a border matching whatever it sits on top of, so
  /// it reads as a "cutout" rather than a stray white ring on a dark
  /// background — the desktop sidebar (dark) passes its own background color
  /// here instead of the white default.
  final Color badgeBorderColor;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarBase64 != null
        ? CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(base64Decode(avatarBase64!)),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.background,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                fontSize: radius * 0.8,
              ),
            ),
          );

    if (style == UserAvatarStatusStyle.ring) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.shade600, width: 2),
        ),
        child: avatar,
      );
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: radius * 0.62,
              height: radius * 0.62,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: badgeBorderColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
