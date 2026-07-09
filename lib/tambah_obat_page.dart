import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'models/drug_model.dart';
import 'services/firestore_service.dart';

class TampilanTambahObat extends StatefulWidget {
  final ModelObat? initialData;
  final bool isEdit;
  final String? docId;

  const TampilanTambahObat({
    super.key,
    this.initialData,
    this.isEdit = false,
    this.docId,
  });

  @override
  State<TampilanTambahObat> createState() => _TampilanTambahObatState();
}

class _TampilanTambahObatState extends State<TampilanTambahObat> {
  late TextEditingController teksNamaObat;
  late TextEditingController _batchController;
  late TextEditingController teksTanggalKedaluwarsa;
  late TextEditingController _hargaController;
  late TextEditingController _hargaBeliController;
  late TextEditingController teksStok;

  bool _isSaving = false;
  String? _errorMessage;

  // Format number to thousand separator (10000 -> "10.000")
  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Parse formatted number back to raw number (remove dots)
  double _parseFormattedNumber(String value) {
    return double.tryParse(value.replaceAll('.', '')) ?? 0.0;
  }

  // Parse formatted number to int (for stok)
  int _parseFormattedInt(String value) {
    return int.tryParse(value.replaceAll('.', '')) ?? 0;
  }

  // Format number with thousand separator
  String _formatNumberDisplay(num? value) {
    if (value == null || value <= 0) return '';
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    teksNamaObat = TextEditingController(
      text: widget.initialData?.namaObat ?? '',
    );
    _batchController = TextEditingController(
      text: widget.initialData?.batch ?? '',
    );
    teksTanggalKedaluwarsa = TextEditingController(
      text: widget.initialData?.expDate ?? '',
    );
    _hargaController = TextEditingController(
      text: _formatNumberDisplay(widget.initialData?.harga),
    );
    _hargaBeliController = TextEditingController(
      text: _formatNumberDisplay(widget.initialData?.hargaBeli),
    );
    teksStok = TextEditingController(
      text: _formatNumberDisplay(widget.initialData?.totalStok),
    );
  }

  @override
  void dispose() {
    teksNamaObat.dispose();
    _batchController.dispose();
    teksTanggalKedaluwarsa.dispose();
    _hargaController.dispose();
    _hargaBeliController.dispose();
    teksStok.dispose();
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
        _parseOCRDate(teksTanggalKedaluwarsa.text) ?? DateTime.now();

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
        teksTanggalKedaluwarsa.text = formattedDate;
      });
    }
  }

  /// Form validation/input handling function
  bool masukkanDataObatManual() {
    if (teksNamaObat.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Nama obat tidak boleh kosong');
      return false;
    }
    if (teksTanggalKedaluwarsa.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Tanggal kedaluwarsa belum dipilih');
      return false;
    }
    if (_parseFormattedNumber(_hargaController.text) <= 0) {
      setState(() => _errorMessage = 'Harga jual harus lebih dari 0');
      return false;
    }
    if (_parseFormattedNumber(_hargaBeliController.text) <= 0) {
      setState(() => _errorMessage = 'Harga beli harus lebih dari 0');
      return false;
    }
    if (_parseFormattedInt(teksStok.text) <= 0) {
      setState(() => _errorMessage = 'Jumlah stok harus lebih dari 0');
      return false;
    }
    return true;
  }

  /// Save button trigger function
  Future<void> klikSimpanObat() async {
    setState(() {
      _errorMessage = null;
    });

    // Validate form input
    if (!masukkanDataObatManual()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedDrug = ModelObat(
        namaObat: teksNamaObat.text,
        batch: _batchController.text,
        expDate: teksTanggalKedaluwarsa.text,
        harga: _parseFormattedNumber(_hargaController.text),
        hargaBeli: _parseFormattedNumber(_hargaBeliController.text),
        totalStok: _parseFormattedInt(teksStok.text),
        kodeBatang: widget.initialData?.kodeBatang ?? '',
      );

      // JIKA DALAM MODE EDIT
      if (widget.isEdit) {
        if (widget.docId == null || widget.docId!.isEmpty) {
          throw 'ID Dokumen Firestore tidak valid untuk melakukan pembaruan data.';
        }

        await LayananFirestore.perbaruiObat(widget.docId!, updatedDrug);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat berhasil diperbarui')),
          );
          Navigator.pop(context, true);
        }
      }
      // JIKA MODE TAMBAH BARU / HASIL SCAN OCR
      else {
        await LayananFirestore.tambahObatManual(updatedDrug);

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
              controller: teksNamaObat,
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
                labelText: 'Nomor Batch (Opsional)',
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
                  'Tanggal Kedaluwarsa *',
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
                    teksTanggalKedaluwarsa.text.isEmpty
                        ? 'Pilih Tanggal (DD/MM/YYYY)'
                        : teksTanggalKedaluwarsa.text,
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Harga Jual (Rp.) *',
                hintText: '50.000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // Format while typing
                final formatted = _formatNumber(value);
                if (formatted != value) {
                  final cursorPos = _hargaController.selection.baseOffset;
                  _hargaController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: cursorPos + (formatted.length - value.length),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hargaBeliController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Harga Beli (Rp.) *',
                hintText: '30.000',
                prefixIcon: const Icon(Icons.shopping_cart),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                final formatted = _formatNumber(value);
                if (formatted != value) {
                  final cursorPos = _hargaBeliController.selection.baseOffset;
                  _hargaBeliController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: cursorPos + (formatted.length - value.length),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teksStok,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah Stok *',
                hintText: '100',
                prefixIcon: const Icon(Icons.inventory),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                final formatted = _formatNumber(value);
                if (formatted != value) {
                  final cursorPos = teksStok.selection.baseOffset;
                  teksStok.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: cursorPos + (formatted.length - value.length),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : klikSimpanObat,
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

// Custom formatter for thousand separator
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove all non-digit characters except dots
    String text = newValue.text.replaceAll('.', '');

    // Parse to number
    final number = int.tryParse(text);
    if (number == null) return oldValue;

    // Format with thousand separator
    String formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
