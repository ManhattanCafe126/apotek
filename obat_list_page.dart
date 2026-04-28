import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/drug_model.dart';
import 'tambah_obat_page.dart';

class ObatListPage extends StatefulWidget {
  const ObatListPage({super.key});

  @override
  State<ObatListPage> createState() => _ObatListPageState();
}

class _ObatListPageState extends State<ObatListPage> {
  TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true; // true = terlama ke terbaru (ASC)
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

    // Sort berdasarkan exp_date
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final expA = _parseExpDate(dataA['exp_date'] ?? '');
      final expB = _parseExpDate(dataB['exp_date'] ?? '');

      // _sortAscending = true (Terlama) → obat yang lagi lama ada di bawah (DESC)
      // _sortAscending = false (Terbaru) → obat yang segera habis ada di atas (ASC)
      return _sortAscending ? expB.compareTo(expA) : expA.compareTo(expB);
    });

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
                  'Urutkan Kadaluarsa:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Terlama'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Terbaru'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: {_sortAscending},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _sortAscending = newSelection.first;
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
                        Icon(
                          Icons.inbox,
                          size: 60,
                          color: Colors.grey[300],
                        ),
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
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;
                    final expDate = data['exp_date'] ?? '';
                    final isExpired = _isExpired(expDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpired ? Colors.red : Colors.deepPurple,
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
                            if (data['batch'] != null && data['batch'].toString().isNotEmpty)
                              Text('Batch: ${data['batch']}', style: const TextStyle(fontSize: 12)),
                            if (data['exp_date'] != null && data['exp_date'].toString().isNotEmpty)
                              Text(
                                'Exp: ${data['exp_date']} ${isExpired ? '⚠️ KADALUARSA' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.red : Colors.black87,
                                ),
                              ),
                            if (data['harga'] != null && (data['harga'] as num) > 0)
                              Text(
                                'Harga: Rp${(data['harga'] as num).toInt()}',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
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
