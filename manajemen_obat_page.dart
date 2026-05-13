import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'models/drug_model.dart';
import 'tambah_obat_page.dart';
import 'utils/expiry_utils.dart';
import 'services/firestore_service.dart';

class ManajemenObatPage extends StatefulWidget {
  const ManajemenObatPage({super.key});

  @override
  State<ManajemenObatPage> createState() => _ManajemenObatPageState();
}

class _ManajemenObatPageState extends State<ManajemenObatPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'semua'; // semua, kritis, rendah, normal
  String _filterExpDate = 'semua'; // semua, terlama, terbaru
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      String? res = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: 'Scan Barcode Obat',
          centerTitle: true,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        isShowFlashIcon: true,
        delayMillis: 1000,
        cameraFace: CameraFace.back,
      );

      if (res != null && res != '-1' && res.isNotEmpty) {
        setState(() {
          _searchController.text = res;
          _searchQuery = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error scanning: $e')),
        );
      }
    }
  }

  DateTime _parseExpDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(9999);
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

  bool _isExpired(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    try {
      final expDate = _parseExpDate(expDateStr);
      return expDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  List<DocumentSnapshot> _filterAndSortDrugs(List<DocumentSnapshot> docs) {
    // Filter berdasarkan search query
    List<DocumentSnapshot> filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nama = (data['nama'] ?? '').toString().toLowerCase();
      final batch = (data['batch'] ?? '').toString().toLowerCase();

      return nama.contains(_searchQuery.toLowerCase()) ||
          batch.contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter berdasarkan status stok
    filtered = filtered.where((doc) {
      final stok = (doc['jumlah_stok'] ?? 0) as num;
      switch (_filterStatus) {
        case 'kritis':
          return stok < 5;
        case 'rendah':
          return stok >= 5 && stok <= 20;
        case 'normal':
          return stok > 20;
        default:
          return true;
      }
    }).toList();

    // Filter berdasarkan exp_date
    if (_filterExpDate == 'terlama') {
      filtered.sort((a, b) {
        final dateA = _parseExpDate(
          (a.data() as Map<String, dynamic>)['exp_date'] ?? '',
        );
        final dateB = _parseExpDate(
          (b.data() as Map<String, dynamic>)['exp_date'] ?? '',
        );
        return dateB.compareTo(dateA); // Terlama = exp date paling jauh
      });
    } else if (_filterExpDate == 'terbaru') {
      filtered.sort((a, b) {
        final dateA = _parseExpDate(
          (a.data() as Map<String, dynamic>)['exp_date'] ?? '',
        );
        final dateB = _parseExpDate(
          (b.data() as Map<String, dynamic>)['exp_date'] ?? '',
        );
        return dateA.compareTo(dateB); // Terbaru = exp date paling dekat
      });
    }

    return filtered;
  }

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
        title: const Text('Manajemen Obat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search Bar with Barcode Scanner
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
                    : IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: _scanBarcode,
                        tooltip: 'Scan Barcode',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Filter Status Stok
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Stok:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('kritis', '🔴 Kritis (<5)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('rendah', '🟡 Rendah (5-20)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('normal', '🟢 Normal (>20)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Filter Exp Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urutkan Exp Date:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildExpDateChip('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _buildExpDateChip('terlama', '📅 Terlama'),
                      const SizedBox(width: 8),
                      _buildExpDateChip('terbaru', '📅 Terbaru'),
                    ],
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
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = _filterAndSortDrugs(docs);

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
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada obat ditemukan'
                              : 'Tidak ada obat sesuai filter',
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
                    final docId = doc.id;
                    final nama = data['nama'] ?? 'N/A';
                    final batch = data['batch'] ?? 'N/A';
                    final stok = (data['jumlah_stok'] ?? 0) as num;
                    final expDate = data['exp_date'] ?? 'N/A';
                    final harga = (data['harga'] ?? 0) as num;
                    final isExpired = _isExpired(expDate);

                    // Tentukan warna dan badge berdasarkan stok
                    Color statusColor;
                    String statusText;
                    if (stok < 5) {
                      statusColor = Colors.red;
                      statusText = 'KRITIS';
                    } else if (stok <= 20) {
                      statusColor = Colors.orange;
                      statusText = 'RENDAH';
                    } else {
                      statusColor = Colors.green;
                      statusText = 'NORMAL';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Batch: $batch',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stok',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${stok.toInt()} unit',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Harga',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      harga > 0 ? 'Rp.${harga.toInt()}' : '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exp Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      expDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isExpired
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    if (expDate != 'N/A')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: _buildStatusBadge(expDate),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddStokDialog(nama, batch),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Stok'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Edit'),
                                      onTap: () {
                                        final drug = DrugData(
                                          nama: data['nama'] ?? '',
                                          batch: data['batch'] ?? '',
                                          expDate: data['exp_date'] ?? '',
                                          harga: (data['harga'] ?? 0)
                                              .toDouble(),
                                          jumlahStok: data['jumlah_stok'] ?? 0,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TambahObatPage(
                                                  initialData: drug,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () =>
                                          _showDeleteDialog(context, docId),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.deepPurple.withValues(alpha: 0.3),
      side: BorderSide(
        color: isSelected ? Colors.deepPurple : Colors.grey,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildExpDateChip(String value, String label) {
    final isSelected = _filterExpDate == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterExpDate = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.orange.withValues(alpha: 0.3),
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.grey,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  void _showAddStokDialog(String nama, String batch) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Stok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obat: $nama',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Batch: $batch',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Jumlah stok tambah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jumlah = int.tryParse(controller.text);
              if (jumlah == null || jumlah <= 0) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Masukkan jumlah yang valid'),
                    ),
                  );
                }
                return;
              }

              try {
                final snapshot = await FirebaseFirestore.instance
                    .collection('obat')
                    .where('nama', isEqualTo: nama)
                    .where('batch', isEqualTo: batch)
                    .limit(1)
                    .get();

                if (snapshot.docs.isNotEmpty) {
                  final docRef = snapshot.docs.first.reference;
                  final currentStok =
                      (snapshot.docs.first['jumlah_stok'] as num?)?.toInt() ??
                          0;
                  final newStok = currentStok + jumlah;

                  await docRef.update({'jumlah_stok': newStok});

                  // Auto-update filter based on new stock status
                  String newFilter = 'semua';
                  if (newStok < 5) {
                    newFilter = 'kritis';
                  } else if (newStok >= 5 && newStok <= 20) {
                    newFilter = 'rendah';
                  } else if (newStok > 20) {
                    newFilter = 'normal';
                  }

                  if (mounted) {
                    setState(() => _filterStatus = newFilter);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Stok $nama ditambah $jumlah unit (Total: $newStok)',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
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
