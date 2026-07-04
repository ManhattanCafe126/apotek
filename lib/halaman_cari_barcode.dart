import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/model_obat.dart';

class HalamanCariBarcode extends StatefulWidget {
  const HalamanCariBarcode({super.key});

  @override
  State<HalamanCariBarcode> createState() => _HalamanCariBarcodState();
}

class _HalamanCariBarcodState extends State<HalamanCariBarcode> {
  String _scannedBarcode = '';
  bool _isScanning = false;
  DataObat? _foundDrug;
  String? _errorMessage;
  String _searchManualBarcode = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Scan barcode
  Future<void> _pindaiBarcode() async {
    setState(() => _isScanning = true);

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
          _scannedBarcode = res;
          _searchManualBarcode = res;
          _searchController.text = res;
        });
        _cariObatPerBarcode(res);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error scanning barcode: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // Cari obat berdasarkan barcode, batch, atau nama
  Future<void> _cariObatPerBarcode(String searchQuery) async {
    setState(() {
      _errorMessage = null;
      _foundDrug = null;
    });

    if (searchQuery.isEmpty) {
      setState(() => _errorMessage = 'Barcode/Batch/Nama tidak boleh kosong');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('obat')
          .get();

      // Filter hasil secara manual untuk pencarian yang lebih fleksibel
      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final barcode = (data['barcode'] ?? '').toString().toLowerCase();
        final batch = (data['batch'] ?? '').toString().toLowerCase();
        final nama = (data['nama'] ?? '').toString().toLowerCase();
        final searchLower = searchQuery.toLowerCase();

        return barcode == searchLower ||
            batch == searchLower ||
            nama.contains(searchLower);
      }).toList();

      if (results.isEmpty) {
        setState(() {
          _errorMessage =
              'Obat dengan barcode/batch/nama "$searchQuery" tidak ditemukan di database';
        });
        return;
      }

      final data = results[0].data();
      final drug = DataObat.dariJson(data);

      setState(() {
        _foundDrug = drug;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error mencari obat: $e');
    }
  }

  DateTime? _parsirTanggalExp(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  bool _apakahKadaluarsa(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    final expDate = _parsirTanggalExp(expDateStr);
    if (expDate == null) return false;
    return expDate.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Obat via Barcode'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _pindaiBarcode,
                icon: const Icon(Icons.qr_code_scanner, size: 30),
                label: const Text('Scan Barcode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'ATAU CARI MANUAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Divider(thickness: 2),

              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchManualBarcode = value);
                },
                decoration: InputDecoration(
                  labelText: 'Cari Batch Atau Nama Obat',
                  hintText: 'Cth: LOT20240415 atau Paracetamol',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchManualBarcode.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchManualBarcode = '';
                              _foundDrug = null;
                              _errorMessage = null;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _cariObatPerBarcode(value);
                  }
                },
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _searchManualBarcode.isEmpty
                    ? null
                    : () => _cariObatPerBarcode(_searchManualBarcode),
                icon: const Icon(Icons.search),
                label: const Text('Cari'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              if (_foundDrug != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Obat ditemukan!',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundDrug!.nama,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        _buatBarisDetail(
                          icon: Icons.tag,
                          label: 'Batch',
                          value: _foundDrug!.batch.isEmpty
                              ? '(Tidak ada)'
                              : _foundDrug!.batch,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(Icons.event, color: Colors.deepPurple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kadaluarsa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _foundDrug!.expDate.isEmpty
                                        ? '(Tidak ada)'
                                        : _foundDrug!.expDate,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _apakahKadaluarsa(_foundDrug!.expDate)
                                          ? Colors.red
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (_apakahKadaluarsa(_foundDrug!.expDate))
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        '⚠️ KADALUARSA',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Harga
                        _buatBarisDetail(
                          icon: Icons.attach_money,
                          label: 'Harga',
                          value: _foundDrug!.harga > 0
                              ? 'Rp${_foundDrug!.harga.toStringAsFixed(0)}'
                              : '(Tidak ada)',
                          valueColor: Colors.green,
                        ),
                        const SizedBox(height: 12),

                        // Stok
                        _buatBarisDetail(
                          icon: Icons.inventory,
                          label: 'Stok',
                          value: '${_foundDrug!.jumlahStok} unit',
                          valueColor: _foundDrug!.jumlahStok == 0
                              ? Colors.red
                              : Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Empty State
              if (_foundDrug == null && _scannedBarcode.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Scan atau ketik barcode untuk mencari obat',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buatBarisDetail({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
