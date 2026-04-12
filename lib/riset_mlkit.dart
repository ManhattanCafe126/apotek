import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'openai_service.dart';
import 'models/obat_ocr_model.dart';

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

  List<ObatOCR> _listObat = []; // 🔥 HASIL AI

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

      setState(() {
        _hasilScan = "📝 OCR selesai. Mengirim ke AI...";
      });

      if (teksMentah.trim().isNotEmpty) {
        await _analisisDenganAI(teksMentah);
      }
    } catch (e) {
      setState(() => _hasilScan = "Gagal OCR: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ================= OPENAI FILTER =================
  Future<void> _analisisDenganAI(String inputTeks) async {
    setState(() => _isAnalyzingAI = true);

    try {
      final hasil =
      await OpenAIService.ekstrakObatDariOCR(inputTeks);

      final List data = jsonDecode(hasil);

      setState(() {
        _listObat =
            data.map((e) => ObatOCR.fromJson(e)).take(5).toList();
      });
    } catch (e) {
      setState(() => _hasilScan = "❌ Gagal parsing AI");
    } finally {
      setState(() => _isAnalyzingAI = false);
    }
  }

  // ================= SCAN BARCODE PER ITEM =================
  Future<void> _scanBarcodePerItem(int index) async {
    try {
      String? res = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: 'Scan Barcode Obat',
          centerTitle: true,
        ),
        isShowFlashIcon: true,
        delayMillis: 800,
        cameraFace: CameraFace.back,
      );

      if (res != null && res != '-1' && res.isNotEmpty) {
        setState(() {
          _listObat[index].barcode = res;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Barcode berhasil disimpan")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal scan barcode: $e")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Faktur Obat"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey[200],
              child: _imageFile == null
                  ? const Center(child: Text("Preview OCR"))
                  : Image.file(_imageFile!, fit: BoxFit.contain),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _ambilGambarOCR,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan Faktur (OCR)"),
            ),

            if (_isAnalyzingAI)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),

            const Divider(),

            // ================= LIST OBAT =================
            const Text(
              "Hasil Deteksi Obat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ..._listObat.asMap().entries.map((entry) {
              int index = entry.key;
              ObatOCR obat = entry.value;

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(obat.nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),

                      Text("Batch: ${obat.batch}"),
                      Text("Expired: ${obat.expired}"),

                      const SizedBox(height: 6),

                      Text(
                        obat.barcode == null
                            ? "Belum ada barcode"
                            : "Barcode: ${obat.barcode}",
                        style: const TextStyle(color: Colors.blue),
                      ),

                      const SizedBox(height: 6),

                      ElevatedButton.icon(
                        onPressed: () => _scanBarcodePerItem(index),
                        icon: const Icon(Icons.qr_code),
                        label: const Text("Scan Barcode"),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}