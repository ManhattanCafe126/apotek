import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'models/drug_model.dart';
import 'models/penjualan_model.dart';
import 'services/firestore_service.dart';

String formatRupiah(double amount) {
  return 'Rp. ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<SalesItem> _cartItems = [];
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final barcode = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: 'Scan Barcode Obat',
          centerTitle: true,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        isShowFlashIcon: true,
        delayMillis: 1000,
      );

      if (barcode != null && barcode != '-1') {
        await _searchDrugByBarcode(barcode);
      }
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _searchDrugByBarcode(String barcode) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('obat')
          .get();

      DrugData? foundDrug;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['barcode'] == barcode ||
            data['batch'] == barcode ||
            (data['nama'] as String).toLowerCase().contains(
              barcode.toLowerCase(),
            )) {
          foundDrug = DrugData(
            nama: data['nama'] ?? '',
            batch: data['batch'] ?? '',
            expDate: data['exp_date'] ?? '',
            harga: (data['harga'] ?? 0).toDouble(),
            jumlahStok: data['jumlah_stok'] ?? 0,
            barcode: data['barcode'] ?? '',
          );
          break;
        }
      }

      if (foundDrug != null) {
        _addToCart(foundDrug);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat tidak ditemukan')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching drug: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _searchDrugByName(String nama) async {
    if (nama.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan nama obat')));
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('obat')
          .get();

      final results = snapshot.docs
          .where(
            (doc) =>
                (doc['nama'] as String).toLowerCase().contains(
                  nama.toLowerCase(),
                ) ||
                ((doc['batch'] as String?)?.toLowerCase().contains(
                      nama.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat tidak ditemukan')),
          );
        }
        return;
      }

      if (mounted) {
        _showSearchResultsDialog(results);
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSearchResultsDialog(List<DocumentSnapshot> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Obat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final data = results[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nama'] ?? ''),
                subtitle: Text(
                  '${data['batch']} - ${formatRupiah((data['harga'] as num?)?.toDouble() ?? 0)}',
                ),
                onTap: () {
                  final drug = DrugData(
                    nama: data['nama'] ?? '',
                    batch: data['batch'] ?? '',
                    expDate: data['exp_date'] ?? '',
                    harga: (data['harga'] ?? 0).toDouble(),
                    jumlahStok: data['jumlah_stok'] ?? 0,
                    barcode: data['barcode'] ?? '',
                  );
                  Navigator.pop(context);
                  _addToCart(drug);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _addToCart(DrugData drug) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.batch == drug.batch && item.nama == drug.nama,
      );

      int newQuantity = 1;
      if (existingIndex >= 0) {
        newQuantity = _cartItems[existingIndex].jumlah + 1;
      }

      if (newQuantity > drug.jumlahStok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok tidak cukup. Stok tersedia: ${drug.jumlahStok}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        _cartItems[existingIndex] = SalesItem(
          drugId: existing.drugId,
          nama: existing.nama,
          batch: existing.batch,
          harga: existing.harga,
          jumlah: newQuantity,
        );
      } else {
        _cartItems.add(
          SalesItem(
            drugId: '',
            nama: drug.nama,
            batch: drug.batch,
            harga: drug.harga,
            jumlah: 1,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${drug.nama} ditambahkan ke keranjang')),
    );
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    final item = _cartItems[index];

    FirebaseFirestore.instance
        .collection('obat')
        .where('nama', isEqualTo: item.nama)
        .where('batch', isEqualTo: item.batch)
        .limit(1)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isEmpty) return;

          final currentStock =
              (snapshot.docs.first['jumlah_stok'] as num?)?.toInt() ?? 0;

          if (newQuantity > currentStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stok tidak cukup. Stok tersedia: $currentStock',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          setState(() {
            _cartItems[index] = SalesItem(
              drugId: item.drugId,
              nama: item.nama,
              batch: item.batch,
              harga: item.harga,
              jumlah: newQuantity,
            );
          });
        });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item dihapus dari keranjang')),
    );
  }

  double get _total {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penjualan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Item: ${_cartItems.length}'),
            const SizedBox(height: 12),
            Text(
              'Total: ${formatRupiah(_total)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Lanjutkan penjualan?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSaleToFirestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSaleToFirestore() async {
    try {
      final penjualan = Penjualan(
        id: '', 
        items: _cartItems,
        createdAt: Timestamp.now(),
      );

      await FirestoreService.simpanPenjualan(penjualan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penjualan berhasil disimpan (${_cartItems.length} item)',
            ),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _cartItems.clear();
          _searchController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error saving sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddMenuDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Obat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _scanBarcode();
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
              icon: const Icon(Icons.search),
              label: const Text('Cari Nama Obat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Obat'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nama atau batch obat...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final nama = _searchController.text;
              Navigator.pop(context);
              _searchDrugByName(nama);
              _searchController.clear();
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan Obat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _showAddMenuDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Obat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          if (_isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(),
            ),

          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Batch: ${item.batch}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeItem(index),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatRupiah(item.harga),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _updateQuantity(
                                          index,
                                          item.jumlah - 1,
                                        ),
                                        icon: const Icon(Icons.remove),
                                        iconSize: 20,
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: TextField(
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          controller: TextEditingController(
                                            text: item.jumlah.toString(),
                                          ),
                                          onChanged: (value) {
                                            final qty =
                                                int.tryParse(value) ?? 1;
                                            _updateQuantity(index, qty);
                                          },
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _updateQuantity(
                                          index,
                                          item.jumlah + 1,
                                        ),
                                        icon: const Icon(Icons.add),
                                        iconSize: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subtotal: ${formatRupiah(item.subtotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Penjualan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatRupiah(_total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cartItems.isEmpty
                      ? null
                      : _showConfirmationDialog,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Konfirmasi Penjualan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
