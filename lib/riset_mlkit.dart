import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'openai_service.dart'; //

class RisetMLKitPage extends StatefulWidget {
  const RisetMLKitPage({super.key});

  @override
  State<RisetMLKitPage> createState() => _RisetMLKitPageState();
}

class _RisetMLKitPageState extends State<RisetMLKitPage> {
  File? _imageFile;
  String _hasilScan = "Belum ada data yang discan.";
  bool _isScanning = false;
  bool _isAnalyzingAI = false;

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
          _hasilScan = "📦 Hasil Barcode:\n$res";
          _imageFile = null;
        });
      } else {
        setState(() => _hasilScan = "Scan dibatalkan.");
      }
    } catch (e) {
      setState(() => _hasilScan = "Gagal scan barcode: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ================= OCR =================
  Future<void> _ambilGambarOCR() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _hasilScan = "Memproses teks OCR...";
      });
      _prosesOCR(pickedFile.path);
    }
  }

  Future<void> _prosesOCR(String path) async {
    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText =
      await _textRecognizer.processImage(inputImage);

      final teksMentah = recognizedText.text;

      String hasilAwal =
          "📝 Teks Terdeteksi:\n$teksMentah\n\n--- ANALISIS DASAR ---";

      if (teksMentah.toUpperCase().contains("EXP") ||
          teksMentah.toUpperCase().contains("ED") ||
          RegExp(r'\d{2}/\d{2}/\d{2,4}').hasMatch(teksMentah)) {
        hasilAwal += "\n[v] Indikasi tanggal kedaluwarsa ditemukan";
      }

      setState(() => _hasilScan = hasilAwal);

      if (teksMentah.trim().isNotEmpty) {
        _analisisDenganOpenAI(teksMentah);
      }
    } catch (e) {
      setState(() => _hasilScan = "Gagal memproses OCR: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ================= OPENAI =================
  Future<void> _analisisDenganOpenAI(String inputTeks) async {
    setState(() {
      _isAnalyzingAI = true;
      _hasilScan += "\n\n🤖 Menganalisis dengan AI (OpenAI)...";
    });

    try {
      final hasilAI =
      await OpenAIService.analisisTeksOCR_OpenAI(inputTeks);

      setState(() {
        _hasilScan += "\n\n--- HASIL ANALISIS AI ---\n$hasilAI";
      });
    } catch (e) {
      setState(() {
        _hasilScan += "\n\n❌ Error analisis AI: $e";
      });
    } finally {
      setState(() => _isAnalyzingAI = false);
    }
  }

  // ================= UI =================
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
              child: _imageFile == null
                  ? const Center(
                child: Text(
                  "Preview Kamera (OCR)",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : Image.file(_imageFile!, fit: BoxFit.contain),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                  (_isScanning || _isAnalyzingAI) ? null : _scanBarcodeNormal,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Scan Barcode"),
                ),
                ElevatedButton.icon(
                  onPressed:
                  (_isScanning || _isAnalyzingAI) ? null : _ambilGambarOCR,
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

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _hasilScan,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
