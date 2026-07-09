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
    final prompt =
        '''
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
            "content": "Anda adalah analis farmasi profesional.",
          },
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
      }),
    );

    if (response.statusCode != 200) {
      return "LiteLLM Error ${response.statusCode}:\n${response.body}";
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'];
  }

  // ==================================================
  // 2️⃣ EKSTRAKSI DATA OBAT DARI OCR (JSON TERSTRUKTUR)
  // ==================================================
  /// Extract medicine via OCR text
  static Future<String> ekstrakObatDariOCR(String teksOCR) async {
    final prompt =
        '''
Teks hasil OCR:
$teksOCR

FORMAT JSON WAJIB (ARRAY - bisa 1+ OBJECTS):
[
  {
    "nama": "nama obat",
    "batch": "nomor batch (jika ada, atau kosong)",
    "exp_date": "tanggal kedaluwarsa dalam format DD/MM/YYYY (jika ada, atau kosong)",
    "harga": 0,
    "jumlah_stok": 0
  },
  {
    "nama": "nama obat kedua",
    "batch": "",
    "exp_date": "DD/MM/YYYY",
    "harga": 0,
    "jumlah_stok": 0
  }
]

ATURAN KETAT:
- Output HANYA JSON ARRAY [] dengan 1 atau lebih obat
- JANGAN gunakan markdown atau format code block
- JANGAN tambahkan teks apapun di luar JSON
- Ekstrak SEMUA obat yang terlihat di teks OCR
- Jika field tidak ditemukan untuk obat tertentu, kosongkan string atau set number ke 0
- harga dan jumlah_stok: jika tidak ada, set ke 0
- exp_date: format DD/MM/YYYY atau kosong jika tidak ada
- Mulai langsung dengan [ dan akhiri dengan ] - tidak ada karakter lain
- Jika hanya 1 obat ditemukan, tetap return ARRAY: [{ ... }]
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
                "Anda adalah analis farmasi yang hanya mengeluarkan JSON ARRAY yang berisi 1 atau lebih obat. Output HANYA JSON VALID dimulai dengan [ dan diakhiri dengan ], tanpa markdown atau teks tambahan.",
          },
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.1,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error mengekstrak data: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    String rawContent = json['choices'][0]['message']['content'];

    // Bersihkan response dari markdown atau karakter extra
    rawContent = rawContent.trim();
    if (rawContent.startsWith('```')) {
      rawContent = rawContent.replaceAll(RegExp(r'^```(json)?\n?'), '');
      rawContent = rawContent.replaceAll(RegExp(r'\n?```$'), '');
      rawContent = rawContent.trim();
    }

    return rawContent;
  }

  // ==================================================
  // 3️⃣ REKOMENDASI PEMBELIAN (JSON TERKUNCI)
  // ==================================================
  /// Generate sales recommendation
  static Future<String> buatRekomendasi(String dataPenjualan) async {
    final prompt =
        '''
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
                "Anda adalah analis pengadaan apotek yang hanya mengeluarkan JSON.",
          },
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.1,
      }),
    );

    if (response.statusCode != 200) {
      return "LiteLLM Error ${response.statusCode}:\n${response.body}";
    }

    final json = jsonDecode(response.body);

    return json['choices'][0]['message']['content'];
  }
}
