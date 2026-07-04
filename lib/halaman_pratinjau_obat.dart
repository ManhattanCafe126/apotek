import 'package:flutter/material.dart';
import 'models/model_obat.dart';
import 'tambah_obat_page.dart';

class HalamanDaftarObat extends StatefulWidget {
  final List<DataObat> drugs;

  const HalamanDaftarObat({required this.drugs, super.key});

  @override
  State<HalamanDaftarObat> createState() => _HalamanDaftarObatState();
}

class _HalamanDaftarObatState extends State<HalamanDaftarObat> {
  late List<DataObat> _remainingDrugs;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _remainingDrugs = List.from(widget.drugs);
  }

  DateTime? _parsirTanggalOCR(String dateStr) {
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
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  String _formatTanggalKeDDMMTTTT(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _bukaTampilObat(int index) {
    debugPrint('=== OPENING FORM ===');
    debugPrint('📝 Index: $index, Remaining drugs: ${_remainingDrugs.length}');
    debugPrint('📝 Drug name: ${_remainingDrugs[index].nama}');

    if (index >= _remainingDrugs.length) {
      debugPrint('Index $index melebihi list length ${_remainingDrugs.length}');
      return;
    }

    final drug = _remainingDrugs[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahObatPage(initialData: drug),
      ),
    ).then((result) {
      debugPrint('=== FORM CLOSED ===');
      debugPrint('Result: $result, Mounted: $mounted');

      if (mounted && result == true) {
        debugPrint('Drug successfully saved: ${drug.nama}');
        debugPrint('Before: $_savedCount/${widget.drugs.length}');

        setState(() {
          _savedCount++;
          _remainingDrugs.removeAt(index);
          debugPrint('After: $_savedCount/${widget.drugs.length}');
          debugPrint('Remaining: ${_remainingDrugs.length}');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ($_savedCount/${widget.drugs.length})'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          debugPrint('🔄 Checking remaining drugs: ${_remainingDrugs.length}');

          if (mounted) {
            if (_remainingDrugs.isNotEmpty) {
              debugPrint('Next drug available, showing dialog');
              _tampilDialogObatBerikutnya();
            } else {
              debugPrint('All drugs finished!');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  debugPrint('Returning to OCR page');
                  Navigator.pop(context, true);
                }
              });
            }
          }
        });
      } else {
        debugPrint('Form cancelled or error');
      }
    });
  }

  void _tampilDialogObatBerikutnya() {
    debugPrint(
      'Showing next drug dialog. Remaining: ${_remainingDrugs.length}',
    );

    if (_remainingDrugs.isEmpty) {
      debugPrint('_remainingDrugs kosong, tidak tampilkan dialog');
      return;
    }

    final nextDrug = _remainingDrugs[0];
    debugPrint('Next drug: ${nextDrug.nama}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Obat Berikutnya'),
        content: Text(
          'Lanjutkan input untuk:\n\n${nextDrug.nama}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('User pilih Selesai');
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Selesai'),
          ),
          TextButton(
            onPressed: () {
              debugPrint('▶️ User pilih Lanjut');
              Navigator.pop(context);
              _bukaTampilObat(0);
            },
            child: const Text(
              'Lanjut',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obat Terdeteksi'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Ditemukan: ${widget.drugs.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.drugs.isEmpty
                      ? 1
                      : _savedCount / widget.drugs.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tersimpan: $_savedCount/${widget.drugs.length} | Tap obat lain untuk lihat/ubah tanggal kadaluarsa',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          Expanded(
            child: _remainingDrugs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Semua obat selesai!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _remainingDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _remainingDrugs[index];
                      final isFirst = index == 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isFirst ? 4 : 2,
                        color: isFirst ? Colors.blue[50] : Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                drug.nama.isEmpty
                                    ? '(Nama tidak terdeteksi)'
                                    : drug.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (drug.batch.isNotEmpty)
                                    Text(
                                      'Batch: ${drug.batch}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (drug.expDate.isNotEmpty)
                                    Text(
                                      'Exp: ${drug.expDate}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: isFirst
                                  ? const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.green,
                                    )
                                  : const Icon(Icons.edit, color: Colors.blue),
                              onTap: () {
                                if (isFirst) {
                                  _bukaTampilObat(index);
                                } else {
                                  _bukaTampilObat(index);
                                }
                              },
                            ),
                          ],
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Batalkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _remainingDrugs.isEmpty
                        ? null
                        : () => _bukaTampilObat(0),
                    icon: const Icon(Icons.edit),
                    label: Text(
                      _remainingDrugs.isEmpty
                          ? 'Selesai'
                          : 'Edit & Input Obat #1',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
