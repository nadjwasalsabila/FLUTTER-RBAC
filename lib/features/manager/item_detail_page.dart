import 'package:flutter/material.dart';

class ItemDetailPage extends StatelessWidget {
  final Map<String, Object?> item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow('SKU', item['sku']?.toString() ?? '-'),
                const Divider(),
                _buildRow('Nama Barang', item['name']?.toString() ?? '-'),
                const Divider(),
                _buildRow('Kategori', item['category']?.toString() ?? '-'),
                const Divider(),
                _buildRow('Lokasi', item['location']?.toString() ?? '-'),
                const Divider(),
                _buildRow('Stok', item['stock']?.toString() ?? '-'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
