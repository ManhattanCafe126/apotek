import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/rekomendasi_model.dart';
import '../models/model_obat.dart';
import '../models/penjualan_model.dart';

class LayananFirestore {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> simpanRekomendasi({
    required List<ItemRestok> restock,
    required List<ItemTidakRestok> tidakRestock,
  }) async {
    await _db.collection('rekomendasi').add({
      'createdAt': FieldValue.serverTimestamp(),
      'sumber': 'AI',
      'restock': restock.map((e) => e.keMap()).toList(),
      'tidak_restock': tidakRestock.map((e) => e.keMap()).toList(),
    });
  }

  static Future<void> tambahObat(DataObat drug) async {
    try {
      debugPrint('Menyimpan obat: ${drug.nama}');
      await _db.collection('obat').add({
        'nama': drug.nama,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'jumlah_stok': drug.jumlahStok,
        'barcode': drug.barcode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Obat berhasil disimpan: ${drug.nama}');
    } catch (e) {
      debugPrint('Error saat menyimpan obat: $e');
      rethrow;
    }
  }

  static Future<void> tambahObatBatch(List<DataObat> drugs) async {
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

  static Stream<QuerySnapshot> streamObat() {
    return _db
        .collection('obat')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> streamHistori() {
    return _db
        .collection('rekomendasi')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> simpanPenjualan(Penjualan penjualan) async {
    try {
      debugPrint(
        'Menyimpan transaksi penjualan: ${penjualan.items.length} item',
      );

      await _db.collection('penjualan').add(penjualan.keMap());

      for (var item in penjualan.items) {
        final obatQuery = await _db
            .collection('obat')
            .where('nama', isEqualTo: item.nama)
            .where('batch', isEqualTo: item.batch)
            .get();

        if (obatQuery.docs.isNotEmpty) {
          final docId = obatQuery.docs.first.id;
          final currentStok = obatQuery.docs.first.data()['jumlah_stok'] ?? 0;
          final newStok = (currentStok as num).toInt() - item.jumlah;

          await _db.collection('obat').doc(docId).update({
            'jumlah_stok': newStok,
            'lastStockOpname': FieldValue.serverTimestamp(),
          });

          debugPrint(
            'Stok ${item.nama} (${item.batch}): $currentStok → $newStok',
          );
        }
      }

      debugPrint(
        'Penjualan & Stock Opname berhasil disimpan dengan total: Rp${penjualan.total.toInt()}',
      );
    } catch (e) {
      debugPrint('Error saat menyimpan penjualan: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> streamPenjualan() {
    return _db
        .collection('penjualan')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> streamStokRealtime() {
    return _db
        .collection('obat')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> tambahStok(
    String namaObat,
    String batch,
    int jumlah,
  ) async {
    try {
      debugPrint('Menambah stok: $namaObat ($batch) + $jumlah unit');

      final obatQuery = await _db
          .collection('obat')
          .where('nama', isEqualTo: namaObat)
          .where('batch', isEqualTo: batch)
          .get();

      if (obatQuery.docs.isNotEmpty) {
        final docId = obatQuery.docs.first.id;
        final currentStok =
            (obatQuery.docs.first.data()['jumlah_stok'] ?? 0) as num;
        final newStok = currentStok.toInt() + jumlah;

        await _db.collection('obat').doc(docId).update({
          'jumlah_stok': newStok,
          'lastStockOpname': FieldValue.serverTimestamp(),
        });

        debugPrint('Stok $namaObat: $currentStok → $newStok');
      } else {
        throw Exception('Obat tidak ditemukan: $namaObat ($batch)');
      }
    } catch (e) {
      debugPrint('Error saat menambah stok: $e');
      rethrow;
    }
  }
}
