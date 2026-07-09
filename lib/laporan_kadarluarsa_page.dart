import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/expiry_utils.dart';
import 'services/firestore_service.dart';

class TampilanLaporanKedaluwarsa extends StatefulWidget {
  const TampilanLaporanKedaluwarsa({super.key});

  @override
  State<TampilanLaporanKedaluwarsa> createState() =>
      _TampilanLaporanKedaluwarsaState();
}

class _TampilanLaporanKedaluwarsaState
    extends State<TampilanLaporanKedaluwarsa> {
  String _selectedFilter = 'all';

  void bukaMenuLaporanKedaluwarsa() {
    // Initialization logic if needed
  }

  /// Build filter buttons
  Widget _buildFilterButtons() {
    final filters = [
      {'key': 'all', 'label': 'Semua', 'icon': Icons.list},
      {'key': 'kadaluarsa', 'label': 'Kadaluarsa', 'icon': Icons.error},
      {'key': 'waspada', 'label': 'Waspada', 'icon': Icons.warning},
      {'key': 'aman', 'label': 'Aman', 'icon': Icons.check_circle},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          final color = _getFilterColor(filter['key'] as String);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter['key'] as String);
              },
              backgroundColor: Colors.white,
              selectedColor: color.withValues(alpha: 0.3),
              side: BorderSide(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? color : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards(Map<String, int> statusCounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            'Kadaluarsa',
            statusCounts['kadaluarsa'] ?? 0,
            const Color(0xFFF44336),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'Waspada',
            statusCounts['waspada'] ?? 0,
            const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            'Aman',
            statusCounts['aman'] ?? 0,
            const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build drug card
  Widget _buildDrugCard(Map<String, dynamic> drug) {
    final status = drug['status'] as String;
    final color = UtilitasKadaluarsa.getStatusColor(status);
    final bgColor = UtilitasKadaluarsa.getStatusBackgroundColor(status);
    final daysLeft = drug['daysLeft'] as int;
    final daysLeftStr = UtilitasKadaluarsa.formatDaysLeft(daysLeft);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  daysLeftStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              drug['nama']?.toString() ?? 'Tidak ada nama',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Batch: ${drug['batch'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Exp: ${drug['exp_date'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (drug['harga'] != null && (drug['harga'] as num) > 0)
              Text(
                'Harga: Rp. ${(drug['harga'] as num).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get color for filter
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'kadaluarsa':
        return const Color(0xFFF44336);
      case 'waspada':
        return const Color(0xFFFF9800);
      case 'aman':
        return const Color(0xFF4CAF50);
      default:
        return Colors.blue;
    }
  }

  /// Filter and sort drugs based on FEFO principle
  List<Map<String, dynamic>> filterDanUrutkanObatFEFO(
    List<QueryDocumentSnapshot> docs,
  ) {
    final drugs = <Map<String, dynamic>>[];
    final statusCounts = <String, int>{
      'kadaluarsa': 0,
      'waspada': 0,
      'aman': 0,
    };

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final expDate = data['exp_date'] ?? '';
      final status = UtilitasKadaluarsa.getExpiryStatus(expDate);

      // Count by status
      if (status == 'Kadaluarsa') {
        statusCounts['kadaluarsa'] = (statusCounts['kadaluarsa'] ?? 0) + 1;
      } else if (status == 'Waspada') {
        statusCounts['waspada'] = (statusCounts['waspada'] ?? 0) + 1;
      } else if (status == 'Aman') {
        statusCounts['aman'] = (statusCounts['aman'] ?? 0) + 1;
      }

      // Filter based on selection
      if (_selectedFilter == 'all' || _selectedFilter == status.toLowerCase()) {
        drugs.add({
          ...data,
          'docId': doc.id,
          'status': status,
          'daysLeft': UtilitasKadaluarsa.getDaysUntilExpiry(expDate),
        });
      }
    }

    // Sort by days left (FEFO principle)
    drugs.sort(
      (a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int),
    );

    return drugs;
  }

  @override
  Widget build(BuildContext context) {
    bukaMenuLaporanKedaluwarsa();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kedaluwarsa'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          const Divider(),
          Expanded(child: tampilkanDaftarLaporanKedaluwarsa()),
        ],
      ),
    );
  }

  /// Display list of expired drugs report
  Widget tampilkanDaftarLaporanKedaluwarsa() {
    return StreamBuilder<QuerySnapshot>(
      stream: LayananFirestore.alirkanDataObat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data obat',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final drugs = filterDanUrutkanObatFEFO(snapshot.data!.docs);

        if (drugs.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada obat dengan status $_selectedFilter',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        // Calculate status counts
        final statusCounts = <String, int>{
          'kadaluarsa': 0,
          'waspada': 0,
          'aman': 0,
        };
        for (var drug in drugs) {
          final status = drug['status'] as String;
          statusCounts[status.toLowerCase()] =
              (statusCounts[status.toLowerCase()] ?? 0) + 1;
        }

        return Column(
          children: [
            _buildSummaryCards(statusCounts),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: drugs.length,
                itemBuilder: (context, index) => _buildDrugCard(drugs[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}
