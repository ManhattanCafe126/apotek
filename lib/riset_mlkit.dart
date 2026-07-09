import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'openai_service.dart';
import 'models/drug_model.dart';
import 'drug_preview_page.dart';

class PengontrolOCR extends StatefulWidget {
  const PengontrolOCR({super.key});

  @override
  State<PengontrolOCR> createState() => _PengontrolOCRState();
}

class _PengontrolOCRState extends State<PengontrolOCR> {
  File? berkasGambar;
  String teksMentah = "Belum ada data yang discan.";
  bool _isScanning = false;
  bool _isAnalyzingAI = false;
  List<ModelObat> _extractedDrugs = [];

  late TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ================= BARCODE =================
  Future<void> _scanBarcodeNormal() async {
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
          teksMentah = "Hasil Barcode:\n$res";
          berkasGambar = null;
        });
      } else {
        setState(() => teksMentah = "Scan dibatalkan.");
      }
    } catch (e) {
      setState(() => teksMentah = "Gagal scan barcode: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ================= OCR =================
  Future<void> ambilGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        berkasGambar = File(pickedFile.path);
        teksMentah = "Memproses teks OCR...";
      });
      prosesGambarDenganMLKit(pickedFile.path);
    }
  }

  /// Process image with ML Kit text recognition
  Future<void> prosesGambarDenganMLKit(String path) async {
    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final hasilOCR = recognizedText.text;

      String hasilAwal =
          "Teks Terdeteksi:\n$hasilOCR\n\n--- ANALISIS DASAR ---";

      if (hasilOCR.toUpperCase().contains("EXP") ||
          hasilOCR.toUpperCase().contains("ED") ||
          RegExp(r'\d{2}/\d{2}/\d{2,4}').hasMatch(hasilOCR)) {
        hasilAwal += "\n[v] Indikasi tanggal kedaluwarsa ditemukan";
      }

      setState(() => teksMentah = hasilAwal);

      if (hasilOCR.trim().isNotEmpty) {
        ekstrakData(hasilOCR);
      }
    } catch (e) {
      setState(() => teksMentah = "Gagal memproses OCR: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ================= OPENAI =================
  Future<void> ekstrakData(String inputTeks) async {
    setState(() {
      _isAnalyzingAI = true;
      _extractedDrugs = [];
      teksMentah += "\n\n Menganalisis dengan AI...";
    });

    try {
      final hasilAI = await OpenAIService.ekstrakObatDariOCR(inputTeks);

      debugPrint('Raw AI Response: $hasilAI');

      dynamic parsedData = jsonDecode(hasilAI);
      debugPrint('Parsed Type: ${parsedData.runtimeType}');

      List<ModelObat> drugsList = [];

      if (parsedData is List) {
        debugPrint('Response is List with ${parsedData.length} items');
        for (int i = 0; i < parsedData.length; i++) {
          final item = parsedData[i];
          debugPrint('Item #$i Type: ${item.runtimeType}');

          if (item is Map<String, dynamic>) {
            try {
              final drug = ModelObat.fromJson(item);
              drugsList.add(drug);
              debugPrint('Drug #$i parsed: ${drug.namaObat}');
            } catch (e) {
              debugPrint('Error parsing drug #$i: $e');
            }
          }
        }
      }
      else if (parsedData is Map<String, dynamic>) {
        debugPrint('Response is single Map (fallback)');
        try {
          final drug = ModelObat.fromJson(parsedData);
          drugsList.add(drug);
          debugPrint('Single drug parsed: ${drug.namaObat}');
        } catch (e) {
          debugPrint('Error parsing single drug: $e');
        }
      } else {
        throw Exception(
          'Format JSON tidak dikenali: ${parsedData.runtimeType}',
        );
      }

      if (drugsList.isEmpty) {
        throw Exception('Tidak ada obat yang berhasil diextract dari OCR');
      }

      setState(() {
        _extractedDrugs = drugsList;
        teksMentah +=
            "\n\n EKSTRAKSI DATA OBAT BERHASIL"
            "\n Total obat ditemukan: ${drugsList.length}"
            "\n\n Daftar obat:";

        for (int i = 0; i < drugsList.length; i++) {
          final drug = drugsList[i];
          teksMentah +=
              "\n\n#${i + 1} ${drug.namaObat}"
              "\n  • Batch: ${drug.batch.isEmpty ? '(tidak ditemukan)' : drug.batch}"
              "\n  • Exp: ${drug.expDate.isEmpty ? '(tidak ditemukan)' : drug.expDate}"
              "\n  • Harga: ${drug.harga > 0 ? 'Rp${drug.formattedHarga}' : '(tidak ada)'}"
              "\n  • Stok: ${drug.totalStok > 0 ? '${drug.formattedStok} unit' : '(tidak ada)'}";
        }
      });
    } catch (e) {
      debugPrint('Parse Error: $e');
      setState(() {
        teksMentah +=
            "\n\n ERROR PARSING DATA\n$e"
            "\n\n Coba scan ulang atau periksa gambar OCR.";
        _extractedDrugs = [];
      });
    } finally {
      setState(() => _isAnalyzingAI = false);
    }
  }

  // Navigate ke list page dengan multiple drugs
  void _navigateToPreview() {
    if (_extractedDrugs.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TampilanValidasiData(drugs: _extractedDrugs),
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua obat berhasil ditambahkan ke database'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          teksMentah = "Belum ada data yang discan.";
          berkasGambar = null;
          _extractedDrugs = [];
        });
      }
    });
  }

  /// Extract raw text handling for display
  Widget ekstrakTeksMentah() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        teksMentah,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode & OCR"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Gambar OCR
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: berkasGambar == null
                  ? const Center(
                      child: Text(
                        "Preview Kamera (OCR)",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Image.file(berkasGambar!, fit: BoxFit.contain),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (_isScanning || _isAnalyzingAI)
                      ? null
                      : _scanBarcodeNormal,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Scan Barcode"),
                ),
                ElevatedButton.icon(
                  onPressed: (_isScanning || _isAnalyzingAI)
                      ? null
                      : ambilGambar,
                  icon: const Icon(Icons.text_fields),
                  label: const Text("Scan OCR"),
                ),
              ],
            ),

            if (_isAnalyzingAI)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 10),
                    Text("AI sedang menganalisis..."),
                  ],
                ),
              ),

            const Divider(thickness: 2),

            ekstrakTeksMentah(),

            // BUTTON: LANJUT KE DAFTAR OBAT (Muncul jika data berhasil diextract)
            if (_extractedDrugs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToPreview,
                  icon: const Icon(Icons.list),
                  label: Text(
                    "Lihat Daftar Obat (${_extractedDrugs.length} ditemukan)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
