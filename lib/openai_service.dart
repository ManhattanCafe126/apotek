import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String apiKey = 'sk-DUmFJ_QUrc0_bhr7VcgN4g';
  static const String baseUrl =
      'https://litellm.koboi2026.biz.id/v1/chat/completions';

  // ==================================================
  // 1️⃣ ANALISIS OCR (TEKS BEBAS, TETAP DIPAKAI)
  // ==================================================
  static Future<String> analisisTeksOCR_OpenAI(String teksOCR) async {
    final prompt = '''
Anda adalah analis farmasi.

Teks hasil OCR:
$teksOCR

Tugas:
- Identifikasi nama obat
- Tanggal kedaluwarsa (jika ada)
- Nomor batch (jika ada)
- Kesimpulan singkat
''';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "Anda adalah analis farmasi profesional."
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.2
      }),
    );

    if (response.statusCode != 200) {
      return "❌ LiteLLM Error ${response.statusCode}:\n${response.body}";
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'];
  }

  // ==================================================
  // 2️⃣ REKOMENDASI PEMBELIAN (JSON TERKUNCI)
  // ==================================================
  static Future<String> generateRekomendasi(String dataPenjualan) async {
    final prompt = '''
Anda adalah sistem analis pengadaan apotek.

Data penjualan obat:
$dataPenjualan

ATURAN WAJIB:
- Output HARUS JSON VALID
- JANGAN gunakan markdown
- JANGAN tambahkan teks di luar JSON
- Gunakan Bahasa Indonesia

FORMAT JSON WAJIB:
{
  "restock": [
    {
      "nama": "string",
      "saran": "Beli ulang",
      "jumlah": 0,
      "alasan": "string"
    }
  ],
  "tidak_restock": [
    {
      "nama": "string",
      "alasan": "string"
    }
  ]
}
''';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
            "Anda adalah analis pengadaan apotek yang hanya mengeluarkan JSON."
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.1
      }),
    );

    if (response.statusCode != 200) {
      return "❌ LiteLLM Error ${response.statusCode}:\n${response.body}";
    }

    final json = jsonDecode(response.body);

    /// ⚠️ Output HARUS berupa JSON string dari AI
    return json['choices'][0]['message']['content'];
  }
  static Future<String> ekstrakObatDariOCR(String teksOCR) async {
    final prompt = '''
  Ekstrak maksimal 5 data obat dari teks berikut.

  Ambil hanya:
  - nama obat
  - batch
  - expired

  Format HARUS JSON array:
  [
    {
      "nama": "...",
      "batch": "...",
      "expired": "..."
    }
  ]

  Teks:
  $teksOCR
  ''';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": "Ekstrak data obat dari OCR."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.1
      }),
    );

    if (response.statusCode != 200) {
      return "[]";
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'];
  }
}
