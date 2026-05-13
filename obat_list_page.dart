import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/drug_model.dart';
import 'tambah_obat_page.dart';
import 'utils/expiry_utils.dart';

class ObatListPage extends StatefulWidget {
  const ObatListPage({super.key});

  @override
  State<ObatListPage> createState() => _ObatListPageState();
}

class _ObatListPageState extends State<ObatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'terbaru'; // 'terbaru' atau 'stok_terbanyak'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper: Parse tanggal format DD/MM/YYYY ke DateTime untuk sorting
  DateTime _parseExpDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(9999); // Taruh di akhir jika kosong
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime(9999);
  }

  // Filter dan sort obat
  List<DocumentSnapshot> _filterAndSortDrugs(List<DocumentSnapshot> docs) {
    List<DocumentSnapshot> filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nama = (data['nama'] ?? '').toString().toLowerCase();
      final batch = (data['batch'] ?? '').toString().toLowerCase();

      return nama.contains(_searchQuery.toLowerCase()) ||
          batch.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort berdasarkan pilihan
    if (_sortBy == 'stok_terbanyak') {
      filtered.sort((a, b) {
        final stokA = (a.data() as Map<String, dynamic>)['jumlah_stok'] ?? 0;
        final stokB = (b.data() as Map<String, dynamic>)['jumlah_stok'] ?? 0;
        return (stokB as num).compareTo(stokA as num); // Terbanyak duluan
      });
    } else {
      // Default: Terbaru (createdAt)
      filtered.sort((a, b) {
        final dateA =
            (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        final dateB =
            (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA); // Terbaru duluan
      });
    }

    return filtered;
  }

  // Helper: Check apakah obat sudah kadaluarsa
  bool _isExpired(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    try {
      final expDate = _parseExpDate(expDateStr);
      return expDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Build status badge for expiry date
  Widget _buildStatusBadge(String expDateStr) {
    final status = ExpiryUtils.getExpiryStatus(expDateStr);
    final color = ExpiryUtils.getStatusColor(status);
    final bgColor = ExpiryUtils.getStatusBackgroundColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Obat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama obat atau batch...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Sort Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'terbaru',
                        label: Text('Terbaru'),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: 'stok_terbanyak',
                        label: Text('Stok Terbanyak'),
                        icon: Icon(Icons.inventory_2),
                      ),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _sortBy = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Obat List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('obat')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada obat',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TambahObatPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Obat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = _filterAndSortDrugs(docs);

                // Tampilkan pesan jika hasil search kosong
                if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
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
                          'Tidak ada obat ditemukan',
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
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;
                    final expDate = data['exp_date'] ?? '';
                    final isExpired = _isExpired(expDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpired
                              ? Colors.red
                              : Colors.deepPurple,
                          child: Icon(
                            isExpired ? Icons.warning : Icons.medication,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['nama'] ?? '(Tidak ada nama)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (data['batch'] != null &&
                                data['batch'].toString().isNotEmpty)
                              Text(
                                'Batch: ${data['batch']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (data['exp_date'] != null &&
                                data['exp_date'].toString().isNotEmpty) ...[
                              Text(
                                'Exp: ${data['exp_date']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Status badge
                              _buildStatusBadge(data['exp_date'] as String),
                            ],
                            if (data['harga'] != null &&
                                (data['harga'] as num) > 0)
                              Text(
                                'Harga: Rp.${(data['harga'] as num).toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            if (data['jumlah_stok'] != null)
                              Text(
                                'Stok: ${data['jumlah_stok'].toString()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () {
                                final drug = DrugData(
                                  nama: data['nama'] ?? '',
                                  batch: data['batch'] ?? '',
                                  expDate: data['exp_date'] ?? '',
                                  harga: (data['harga'] ?? 0).toDouble(),
                                  jumlahStok: data['jumlah_stok'] ?? 0,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TambahObatPage(initialData: drug),
                                  ),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () => _showDeleteDialog(context, docId),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahObatPage()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: const Text('Apakah Anda yakin ingin menghapus obat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('obat').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Obat berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
