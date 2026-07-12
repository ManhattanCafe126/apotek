import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/drug_model.dart';
import 'tambah_obat_page.dart';
import 'services/firestore_service.dart';

class TampilanValidasiData extends StatefulWidget {
  final List<ModelObat> drugs;

  const TampilanValidasiData({required this.drugs, super.key});

  @override
  State<TampilanValidasiData> createState() => _TampilanValidasiDataState();
}

class _TampilanValidasiDataState extends State<TampilanValidasiData> {
  late List<ModelObat> dataObatHasilEkstraksi;
  late Map<int, bool> _selectedItems;
  int _savedViaCheckboxCount = 0; // Track obat yang disimpan via checkbox

  @override
  void initState() {
    super.initState();
    dataObatHasilEkstraksi = List.from(widget.drugs);
    _selectedItems = {};
    for (int i = 0; i < widget.drugs.length; i++) {
      _selectedItems[i] = false;
    }
  }

  int get _checkedCount => _selectedItems.values.where((v) => v).length;

  void _toggleSelectAll(bool value) {
    setState(() {
      for (int i = 0; i < widget.drugs.length; i++) {
        _selectedItems[i] = value;
      }
    });
  }

  void _toggleItem(int index, bool value) {
    setState(() {
      _selectedItems[index] = value;
    });
  }

  bool _isDrugValid(ModelObat drug) {
    return drug.namaObat.isNotEmpty &&
        drug.batch.isNotEmpty &&
        drug.expDate.isNotEmpty &&
        drug.harga > 0 &&
        drug.hargaBeli > 0 &&
        drug.totalStok > 0;
  }

  List<String> _getInvalidFields(ModelObat drug) {
    final invalid = <String>[];
    if (drug.namaObat.isEmpty) invalid.add('Nama');
    if (drug.batch.isEmpty) invalid.add('Batch');
    if (drug.expDate.isEmpty) invalid.add('Tanggal Kadaluarsa');
    if (drug.harga <= 0) invalid.add('Harga Jual');
    if (drug.hargaBeli <= 0) invalid.add('Harga Beli');
    if (drug.totalStok <= 0) invalid.add('Stok');
    return invalid;
  }

  void ubahDetailData(int index, ModelObat updatedDrug) {
    setState(() {
      dataObatHasilEkstraksi[index] = updatedDrug;
    });
  }

  /// Hapus item yang dipilih dari daftar (dengan opsi hapus dari DB)
  void _hapusTerpilih() {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih item yang ingin dihapus'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Item Terpilih'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yakin ingin menghapus $_checkedCount item?'),
            const SizedBox(height: 16),
            const Text(
              'Pilih aksi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executeDelete(deleteFromDb: false);
            },
            icon: const Icon(Icons.remove_red_eye, size: 18),
            label: const Text('Hapus dari Daftar Saja'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executeDelete(deleteFromDb: true);
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Hapus dari DB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete({required bool deleteFromDb}) async {
    final countToRemove = _checkedCount;
    final drugsToDelete = <ModelObat>[];
    final indicesToRemove = <int>[];

    for (int i = 0; i < dataObatHasilEkstraksi.length; i++) {
      if (_selectedItems[i] == true) {
        drugsToDelete.add(dataObatHasilEkstraksi[i]);
        indicesToRemove.add(i);
      }
    }

    if (deleteFromDb) {
      // Hapus dari Firestore juga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Menghapus dari database...'),
            ],
          ),
        ),
      );

      try {
        final db = FirebaseFirestore.instance;
        for (final drug in drugsToDelete) {
          // Cari dan hapus dari Firestore berdasarkan nama dan batch
          final snapshot = await db
              .collection('obat')
              .where('nama', isEqualTo: drug.namaObat)
              .where('batch', isEqualTo: drug.batch)
              .get();

          for (final doc in snapshot.docs) {
            await doc.reference.delete();
          }
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error hapus dari DB: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      // Hapus dari daftar (dari belakang ke depan agar index tidak bergeser)
      indicesToRemove.sort((a, b) => b.compareTo(a));
      for (final index in indicesToRemove) {
        dataObatHasilEkstraksi.removeAt(index);
        _selectedItems.remove(index);
      }

      // Reset checkbox
      _selectedItems = {};
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleteFromDb
              ? '$countToRemove item dihapus dari daftar dan database'
              : '$countToRemove item dihapus dari daftar',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Track item yang sedang dalam proses edit batch
  List<int> _batchEditQueue = [];

  void tampilkanDataValidasi(int index) {
    if (index >= dataObatHasilEkstraksi.length) return;

    // Jika sedang dalam mode edit batch, simpan queue saat ini
    final isBatchEdit = _batchEditQueue.contains(index);

    final drug = dataObatHasilEkstraksi[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TampilanTambahObat(initialData: drug),
      ),
    ).then((result) {
      if (!mounted) return;

      if (result == true) {
        // Hapus obat dari daftar preview karena sudah tersimpan
        setState(() {
          dataObatHasilEkstraksi.removeAt(index);
          _selectedItems.remove(index);
          _batchEditQueue.remove(index);

          // Update index di _batchEditQueue (karena list sudah berubah)
          _batchEditQueue = _batchEditQueue.map((i) => i > index ? i - 1 : i).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${drug.namaObat} tersimpan & dihapus dari daftar'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );

        // Jika dalam mode batch edit, lanjut ke item berikutnya
        if (isBatchEdit && _batchEditQueue.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _batchEditQueue.isNotEmpty) {
              tampilkanDataValidasi(_batchEditQueue.first);
            }
          });
        }
      } else if (result is ModelObat) {
        ubahDetailData(index, result);
      }
    });
  }

  /// Edit semua item yang dipilih satu per satu
  void _editTerpilih() {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih item yang ingin diedit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ambil semua index yang dipilih
    final selectedToEdit = <int>[];
    for (int i = 0; i < _selectedItems.length; i++) {
      if (_selectedItems[i] == true) {
        selectedToEdit.add(i);
      }
    }

    if (selectedToEdit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada item untuk diedit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set queue untuk batch edit
    _batchEditQueue = selectedToEdit;

    // Tampilkan snackbar info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Akan mengedit ${selectedToEdit.length} item satu per satu'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // Mulai dengan item pertama
    tampilkanDataValidasi(selectedToEdit.first);
  }

  Future<void> kliSimpanKeFirestore() async {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 obat untuk disimpan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final invalidDrugs = <ModelObat>[];
    final validDrugs = <ModelObat>[];

    for (int i = 0; i < dataObatHasilEkstraksi.length; i++) {
      if (_selectedItems[i] != true) continue;

      final drug = dataObatHasilEkstraksi[i];
      if (_isDrugValid(drug)) {
        validDrugs.add(drug);
      } else {
        invalidDrugs.add(drug);
      }
    }

    if (validDrugs.isEmpty && invalidDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih obat yang ingin disimpan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (invalidDrugs.isNotEmpty) {
      final invalidNames = invalidDrugs.map((d) => '• ${d.namaObat}').join('\n');
      final invalidFields = _getInvalidFields(invalidDrugs.first);

      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Data Tidak Lengkap'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Obat berikut belum lengkap:'),
                const SizedBox(height: 8),
                Text(
                  invalidNames,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Field kosong: ${invalidFields.join(", ")}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Klik "Edit Obat" untuk melengkapi data,\natau "Simpan Saja" untuk menyimpan yang sudah lengkap.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan Saja'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
      if (!mounted) return;

      if (validDrugs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada obat dengan data lengkap'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyimpanan'),
        content: Text(
          'Akan disimpan: ${validDrugs.length} obat\n\nPastikan semua data sudah benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Menyimpan obat...'),
          ],
        ),
      ),
    );

    try {
      int saved = 0;

      for (var drug in validDrugs) {
        try {
          await LayananFirestore.tambahObatManual(drug);
          saved++;
        } catch (e) {
          debugPrint('Error saving ${drug.namaObat}: $e');
        }
      }

      if (mounted) Navigator.of(context).pop();

      // Update counter untuk obat yang disimpan via checkbox
      _savedViaCheckboxCount += saved;

      if (_savedViaCheckboxCount >= 1) {
        // Ada obat tersimpan, kembali ke halaman utama
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total $_savedViaCheckboxCount obat tersimpan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Kembali ke halaman utama
        }
      } else {
        // Tidak ada yang tersimpan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pilih minimal 1 obat untuk disimpan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Obat untuk Disimpan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              final allSelected = _checkedCount == dataObatHasilEkstraksi.length;
              _toggleSelectAll(!allSelected);
            },
            icon: Icon(
              _checkedCount == dataObatHasilEkstraksi.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              _checkedCount == dataObatHasilEkstraksi.length ? 'Uncheck All' : 'Check All',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${dataObatHasilEkstraksi.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _checkedCount > 0 ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_checkedCount dipilih',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: dataObatHasilEkstraksi.isEmpty ? 1 : _checkedCount / dataObatHasilEkstraksi.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dataObatHasilEkstraksi.length,
              itemBuilder: (context, index) {
                final drug = dataObatHasilEkstraksi[index];
                final isChecked = _selectedItems[index] ?? false;
                final isValid = _isDrugValid(drug);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  color: isChecked ? Colors.green.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isChecked ? Colors.green : Colors.grey.shade300,
                      width: isChecked ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _toggleItem(index, !isChecked),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (value) => _toggleItem(index, value ?? false),
                              activeColor: Colors.green,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isChecked ? Colors.green : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        drug.namaObat.isEmpty ? '(Nama tidak terdeteksi)' : drug.namaObat,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: drug.namaObat.isEmpty ? Colors.red : Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isValid)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '!',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (drug.batch.isNotEmpty)
                                      _buildChip(Icons.tag, 'Batch: ${drug.batch}'),
                                    if (drug.expDate.isNotEmpty)
                                      _buildChip(Icons.calendar_today, 'Exp: ${drug.expDate}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (drug.harga > 0)
                                      Text(
                                        'Jual: Rp${drug.formattedHarga}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (drug.harga > 0 && drug.hargaBeli > 0)
                                      const SizedBox(width: 8),
                                    if (drug.hargaBeli > 0)
                                      Text(
                                        'Beli: Rp${drug.formattedHargaBeli}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (drug.totalStok > 0)
                                      Text(
                                        'Stok: ${drug.formattedStok}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => tampilkanDataValidasi(index),
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                            tooltip: 'Edit Obat',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Sisa', '${dataObatHasilEkstraksi.length}', Colors.deepPurple),
                      _buildSummaryItem('Dipilih', '$_checkedCount', Colors.green),
                      _buildSummaryItem('Selesai', '$_savedViaCheckboxCount', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Baris aksi batch (Hapus & Edit Terpilih)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _checkedCount > 0 ? _hapusTerpilih : null,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Hapus Terpilih'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _checkedCount > 0 ? _editTerpilih : null,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Terpilih'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Baris tombol utama
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close),
                          label: const Text('Batalkan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (_savedViaCheckboxCount >= 1 || dataObatHasilEkstraksi.isEmpty)
                              ? () {
                                  Navigator.pop(context, true);
                                }
                              : null,
                          icon: const Icon(Icons.home),
                          label: Text(
                            _savedViaCheckboxCount >= 1
                                ? 'Kembali ke Utama'
                                : (dataObatHasilEkstraksi.isEmpty ? 'Semua Selesai' : 'Simpan Obat Dulu'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_savedViaCheckboxCount >= 1 || dataObatHasilEkstraksi.isEmpty)
                                ? Colors.deepPurple
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
