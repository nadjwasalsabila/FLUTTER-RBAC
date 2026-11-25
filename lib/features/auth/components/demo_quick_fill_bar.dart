import 'package:flutter/material.dart';

import '../types/auth_user.dart';

class DemoQuickFillBar extends StatelessWidget {
  const DemoQuickFillBar({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onSelectUser,
  });

  final List<AuthUser> users;
  final bool isLoading;
  final ValueChanged<AuthUser> onSelectUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Isi cepat akun demo:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF145858),
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const LinearProgressIndicator(color: Color(0xFF145858))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: users.map((user) {
              return ActionChip(
                backgroundColor: const Color(0xFFC8E0CA),
                side: BorderSide.none,
                label: Text(
                  '${user.fullName} (${user.roleId})',
                  style: const TextStyle(
                    color: Color(0xFF102A2A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                onPressed: () => onSelectUser(user),
              );
            }).toList(),
          ),
      ],
    );
  }
}
