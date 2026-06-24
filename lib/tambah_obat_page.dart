import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'models/drug_model.dart';
import 'services/firestore_service.dart';

class TambahObatPage extends StatefulWidget {
  final DrugData? initialData;
  final bool isEdit; // Bendera penanda halaman dibuka untuk mode EDIT
  final String? docId; // ID Dokumen dari Firestore obat yang mau di-edit

  const TambahObatPage({
    super.key,
    this.initialData,
    this.isEdit = false, // Nilai bawaan/default adalah false (mode tambah baru)
    this.docId,
  });

  @override
  State<TambahObatPage> createState() => _TambahObatPageState();
}

class _TambahObatPageState extends State<TambahObatPage> {
  late TextEditingController _namaController;
  late TextEditingController _batchController;
  late TextEditingController _expDateController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahStokController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.initialData?.nama ?? '',
    );
    _batchController = TextEditingController(
      text: widget.initialData?.batch ?? '',
    );
    _expDateController = TextEditingController(
      text: widget.initialData?.expDate ?? '',
    );
    _hargaController = TextEditingController(
      text: widget.initialData != null && widget.initialData!.harga > 0
          ? widget.initialData!.harga.toString()
          : '',
    );
    _jumlahStokController = TextEditingController(
      text: widget.initialData != null && widget.initialData!.jumlahStok > 0
          ? widget.initialData!.jumlahStok.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _batchController.dispose();
    _expDateController.dispose();
    _hargaController.dispose();
    _jumlahStokController.dispose();
    super.dispose();
  }

  DateTime? _parseOCRDate(String dateStr) {
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

  String _formatDateToDDMMYYYY(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openDatePicker() async {
    DateTime initialDate =
        _parseOCRDate(_expDateController.text) ?? DateTime.now();

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        currentDate: initialDate,
        selectedDayHighlightColor: Colors.deepPurple,
        dayTextStyle: const TextStyle(color: Colors.black87),
        weekdayLabelTextStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        controlsTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        okButtonTextStyle: const TextStyle(color: Colors.deepPurple),
        cancelButtonTextStyle: const TextStyle(color: Colors.grey),
      ),
      value: [initialDate],
      dialogSize: const Size(325, 400),
    );

    if (results != null && results.isNotEmpty && results[0] != null) {
      String formattedDate = _formatDateToDDMMYYYY(results[0]!);
      setState(() {
        _expDateController.text = formattedDate;
      });
    }
  }

  Future<void> _simpanObat() async {
    setState(() {
      _errorMessage = null;
    });

    if (_namaController.text.isEmpty) {
      setState(() => _errorMessage = 'Nama obat tidak boleh kosong');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedDrug = DrugData(
        nama: _namaController.text,
        batch: _batchController.text,
        expDate: _expDateController.text,
        harga: double.tryParse(_hargaController.text) ?? 0.0,
        jumlahStok: int.tryParse(_jumlahStokController.text) ?? 0,
        barcode: widget.initialData?.barcode ?? '',
      );

      // JIKA DALAM MODE EDIT
      if (widget.isEdit) {
        if (widget.docId == null || widget.docId!.isEmpty) {
          throw 'ID Dokumen Firestore tidak valid untuk melakukan pembaruan data.';
        }

        await FirestoreService.updateObat(widget.docId!, updatedDrug);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat berhasil diperbarui')),
          );
          Navigator.pop(context, true);
        }
      }
      // JIKA MODE TAMBAH BARU / HASIL SCAN OCR
      else {
        await FirestoreService.tambahObat(updatedDrug);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat berhasil ditambahkan')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menyimpan: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Obat' : 'Tambah Obat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner bantuan OCR disembunyikan otomatis jika sedang mode Edit
            if (widget.initialData != null && !widget.isEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Data dari OCR terdeteksi. Silakan sesuaikan jika diperlukan.',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Obat *',
                hintText: 'Contoh: Paracetamol 500mg',
                prefixIcon: const Icon(Icons.medication),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _batchController,
              decoration: InputDecoration(
                labelText: 'Nomor Batch',
                hintText: 'Contoh: LOT20240415',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal Kedaluwarsa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _openDatePicker,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _expDateController.text.isEmpty
                        ? 'Pilih Tanggal (DD/MM/YYYY)'
                        : _expDateController.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple[300]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Harga (Rp.)',
                hintText: '50000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahStokController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok',
                hintText: '100',
                prefixIcon: const Icon(Icons.inventory),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _simpanObat,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving
                    ? 'Menyimpan...'
                    : (widget.isEdit ? 'Perbarui Obat' : 'Simpan Obat'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
