import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/rekomendasi_model.dart';
import '../models/drug_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SIMPAN REKOMENDASI
  static Future<void> simpanRekomendasi({
    required List<RestockItem> restock,
    required List<TidakRestockItem> tidakRestock,
  }) async {
    await _db.collection('rekomendasi').add({
      'createdAt': FieldValue.serverTimestamp(),
      'sumber': 'AI',
      'restock': restock.map((e) => e.toMap()).toList(),
      'tidak_restock': tidakRestock.map((e) => e.toMap()).toList(),
    });
  }

  /// TAMBAH OBAT BARU
  static Future<void> tambahObat(DrugData drug) async {
    try {
      debugPrint('📝 Menyimpan obat: ${drug.nama}');
      await _db.collection('obat').add({
        'nama': drug.nama,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'jumlah_stok': drug.jumlahStok,
        'barcode': drug.barcode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Obat berhasil disimpan: ${drug.nama}');
    } catch (e) {
      debugPrint('❌ Error saat menyimpan obat: $e');
      rethrow;
    }
  }

  /// TAMBAH MULTIPLE OBAT (BATCH)
  static Future<void> tambahObatBatch(List<DrugData> drugs) async {
    if (drugs.isEmpty) throw Exception('Daftar obat kosong');

    for (var drug in drugs) {
      await _db.collection('obat').add({
        'nama': drug.nama,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'jumlah_stok': drug.jumlahStok,
        'barcode': drug.barcode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// AMBIL DAFTAR OBAT
  static Stream<QuerySnapshot> streamObat() {
    return _db
        .collection('obat')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// AMBIL HISTORI REKOMENDASI
  static Stream<QuerySnapshot> streamHistori() {
    return _db
        .collection('rekomendasi')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
