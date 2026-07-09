import 'package:flutter/material.dart';
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
  final Set<int> _alreadySavedIndices = {};

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

  void tampilkanDataValidasi(int index) {
    if (index >= dataObatHasilEkstraksi.length) return;

    final drug = dataObatHasilEkstraksi[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TampilanTambahObat(initialData: drug),
      ),
    ).then((result) {
      if (!mounted) return;

      if (result == true) {
        setState(() {
          _selectedItems[index] = true;
          _alreadySavedIndices.add(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${drug.namaObat} tersimpan - otomatis diceklis'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result is ModelObat) {
        ubahDetailData(index, result);
      }
    });
  }

  void ubahDetailData(int index, ModelObat updatedDrug) {
    setState(() {
      dataObatHasilEkstraksi[index] = updatedDrug;
    });
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
    final alreadySavedCount = <int>[];

    for (int i = 0; i < widget.drugs.length; i++) {
      if (_selectedItems[i] != true) continue;

      if (_alreadySavedIndices.contains(i)) {
        alreadySavedCount.add(i);
        continue;
      }

      final drug = widget.drugs[i];
      if (_isDrugValid(drug)) {
        validDrugs.add(drug);
      } else {
        invalidDrugs.add(drug);
      }
    }

    if (validDrugs.isEmpty && invalidDrugs.isEmpty) {
      final savedViaForm = alreadySavedCount.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedViaForm > 0
                ? '$savedViaForm obat sudah tersimpan via form'
                : 'Pilih obat yang ingin disimpan',
          ),
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
                if (alreadySavedCount.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${alreadySavedCount.length} obat sudah tersimpan',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Obat berikut belum lengkap:'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alreadySavedCount.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${alreadySavedCount.length} obat sudah tersimpan via form',
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Akan disimpan sekarang: ${validDrugs.length} obat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Pastikan semua data sudah benar.'),
          ],
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

      if (mounted) {
        final totalSaved = saved + alreadySavedCount.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              totalSaved > 0
                  ? 'Total tersimpan: $totalSaved obat'
                  : 'Tidak ada obat yang disimpan',
            ),
            backgroundColor: totalSaved > 0 ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, true);
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
              final allSelected = _checkedCount == widget.drugs.length;
              _toggleSelectAll(!allSelected);
            },
            icon: Icon(
              _checkedCount == widget.drugs.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              _checkedCount == widget.drugs.length ? 'Uncheck All' : 'Check All',
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
                      'Total: ${widget.drugs.length}',
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
                  value: widget.drugs.isEmpty ? 1 : _checkedCount / widget.drugs.length,
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
                final alreadySaved = _alreadySavedIndices.contains(index);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  color: alreadySaved
                      ? Colors.green.shade100
                      : (isChecked ? Colors.green.shade50 : Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: alreadySaved
                          ? Colors.green
                          : (isChecked ? Colors.green : Colors.grey.shade300),
                      width: alreadySaved ? 3 : (isChecked ? 2 : 1),
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
                              onChanged: alreadySaved
                                  ? null
                                  : (value) => _toggleItem(index, value ?? false),
                              activeColor: Colors.green,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: alreadySaved
                                  ? Colors.green.shade700
                                  : (isChecked ? Colors.green : Colors.grey.shade400),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: alreadySaved
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text(
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
                                    if (alreadySaved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check, color: Colors.white, size: 12),
                                            SizedBox(width: 2),
                                            Text(
                                              'Tersimpan',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (!isValid)
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
                      _buildSummaryItem('Total', '${widget.drugs.length}', Colors.deepPurple),
                      _buildSummaryItem('Dipilih', '$_checkedCount', Colors.green),
                      _buildSummaryItem('Belum', '${widget.drugs.length - _checkedCount}', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: _checkedCount > 0 ? kliSimpanKeFirestore : null,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _checkedCount > 0 ? 'Simpan ($_checkedCount)' : 'Pilih Obat Dulu',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _checkedCount > 0 ? Colors.green : Colors.grey,
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
