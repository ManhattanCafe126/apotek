import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'models/penjualan_model.dart';
import 'services/firestore_service.dart';

/// Format currency to Rupiah with thousand separator
String formatRupiah(double amount) {
  return 'Rp. ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

class HistoriPenjualanPage extends StatefulWidget {
  const HistoriPenjualanPage({super.key});

  @override
  State<HistoriPenjualanPage> createState() => _HistoriPenjualanPageState();
}

class _HistoriPenjualanPageState extends State<HistoriPenjualanPage> {
  String _selectedFilter = 'hari_ini'; // 'hari_ini', 'kemarin', 'tanggal'
  DateTime? _selectedDate;

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Parse timestamp ke format DD/MM HH:MM
  String _formatTransactionTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Filter transaksi berdasarkan pilihan filter
  List<DocumentSnapshot> _filterTransactions(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;

      if (timestamp == null) return false;

      final transactionDate = timestamp.toDate();
      final transactionDateOnly = DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
      );

      if (_selectedFilter == 'hari_ini') {
        return _isToday(transactionDateOnly);
      } else if (_selectedFilter == 'kemarin') {
        return _isYesterday(transactionDateOnly);
      } else if (_selectedFilter == 'tanggal' && _selectedDate != null) {
        return transactionDateOnly == _selectedDate;
      }

      return false;
    }).toList();
  }

  /// Tampilkan date picker untuk pilih tanggal
  Future<void> _showDatePicker() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        currentDate: _selectedDate ?? DateTime.now(),
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.isNotEmpty && mounted) {
      setState(() {
        _selectedDate = results[0];
        _selectedFilter = 'tanggal';
      });
    }
  }

  /// Tampilkan detail transaksi
  void _showTransactionDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List?) ?? [];
    final items = itemsList
        .map((item) => SalesItem.fromMap(item as Map<String, dynamic>))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail Transaksi - ${_formatTransactionTime(data['createdAt'])}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.nama),
                subtitle: Text('${item.batch} × ${item.jumlah}'),
                trailing: Text(
                  formatRupiah(item.subtotal.toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Total: ${formatRupiah((data['total'] as num).toDouble())}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Penjualan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Tanggal:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'hari_ini',
                            label: Text('Hari Ini'),
                          ),
                          ButtonSegment(
                            value: 'kemarin',
                            label: Text('Kemarin'),
                          ),
                          ButtonSegment(
                            value: 'tanggal',
                            label: Text('Tanggal'),
                          ),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedFilter = newSelection.first;
                            if (_selectedFilter == 'tanggal') {
                              _showDatePicker();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedFilter == 'tanggal' && _selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Tanggal: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Total Penjualan Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.streamPenjualan(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final filteredDocs = _filterTransactions(snapshot.data!.docs);
                final totalPenjualan = filteredDocs.isEmpty
                    ? 0
                    : filteredDocs.fold<int>(
                        0,
                        (sum, doc) =>
                            sum + ((doc['total'] as num?)?.toInt() ?? 0),
                      );

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Penjualan:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatRupiah(totalPenjualan.toDouble()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.streamPenjualan(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada histori penjualan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredDocs = _filterTransactions(snapshot.data!.docs);

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada transaksi pada tanggal tersebut',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['createdAt'] as Timestamp?;
                    final total = (data['total'] as num?)?.toInt() ?? 0;
                    final itemsList = (data['items'] as List?) ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _showTransactionDetails(doc),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              itemsList.length.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'Transaksi ${timestamp != null ? _formatTransactionTime(timestamp) : 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${itemsList.length} item',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          formatRupiah(total.toDouble()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
