import 'package:flutter/material.dart';

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF145858),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.warehouse_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masuk Gudang RBAC',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF102A2A),
                ),
              ),
              Text(
                'Silakan masuk untuk mengelola stok',
                style: TextStyle(fontSize: 13, color: Color(0xFF145858)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
