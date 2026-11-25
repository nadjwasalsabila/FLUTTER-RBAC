import 'package:flutter/material.dart';

class StaffSummaryHeader extends StatelessWidget {
  const StaffSummaryHeader({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.itemCount,
    required this.totalStock,
  });

  final String? userName;
  final String? roleLabel;
  final int itemCount;
  final int totalStock;

  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _darkText = Color(0xFF102A2A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softMint, width: 1.2),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: _softMint,
                child: Icon(Icons.person_outline, color: _primaryTeal),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Petugas Gudang',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                  if (roleLabel != null)
                    Text(
                      'Role: $roleLabel',
                      style: const TextStyle(fontSize: 12, color: _primaryTeal),
                    ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                backgroundColor: _softMint,
                side: BorderSide.none,
                label: Text(
                  '$itemCount SKU',
                  style: const TextStyle(color: _darkText, fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                backgroundColor: _warmAmber,
                side: BorderSide.none,
                label: Text(
                  'Total Stok: $totalStock',
                  style: const TextStyle(color: _darkText, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaffStatusBanner extends StatelessWidget {
  const StaffStatusBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  static const _primaryTeal = Color(0xFF145858);
  static const _warmAmber = Color(0xFFF7B318);
  static const _darkText = Color(0xFF102A2A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFF6E0) : const Color(0xFFE5F3E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isError ? _warmAmber : _primaryTeal),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle,
              color: isError ? _darkText : _primaryTeal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: _darkText, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: _darkText),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
