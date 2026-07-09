import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/rekomendasi_model.dart';
import '../models/drug_model.dart';
import '../models/penjualan_model.dart';

class LayananFirestore {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> simpanRekomendasi({
    required List<ItemStokUlang> restock,
    required List<ItemTidakRestok> tidakRestock,
  }) async {
    await _db.collection('rekomendasi').add({
      'timestamp': FieldValue.serverTimestamp(),
      'sumber': 'AI',
      'restock': restock.map((e) => e.toJson()).toList(),
      'tidakRestock': tidakRestock.map((e) => e.toJson()).toList(),
    });
  }

  static Stream<QuerySnapshot> alirkanRiwayatRekomendasi() {
    return _db
        .collection('rekomendasi')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> tambahObatManual(ModelObat drug) async {
    try {
      debugPrint('Menyimpan obat baru: ${drug.namaObat}');

      // Pengecekan Batch Duplikat di Firestore
      if (drug.batch.isNotEmpty) {
        final cekBatch = await _db
            .collection('obat')
            .where('batch', isEqualTo: drug.batch)
            .get();

        if (cekBatch.docs.isNotEmpty) {
          throw 'Nomor batch "${drug.batch}" sudah terdaftar di database!';
        }
      }

      await _db.collection('obat').add({
        'nama': drug.namaObat,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'harga_beli': drug.hargaBeli,
        'jumlah_stok': drug.totalStok,
        'barcode': drug.kodeBatang,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Obat berhasil disimpan: ${drug.namaObat}');
    } catch (e) {
      debugPrint('Error saat menyimpan obat: $e');
      rethrow;
    }
  }

  static Future<void> perbaruiObat(String docId, ModelObat drug) async {
    try {
      debugPrint('Mengupdate obat: ${drug.namaObat} dengan ID: $docId');

      // Validasi Batch Cerdas: Hanya lempar error jika nomor batch dipakai dokumen LAIN
      if (drug.batch.isNotEmpty) {
        final cekBatch = await _db
            .collection('obat')
            .where('batch', isEqualTo: drug.batch)
            .get();

        for (var doc in cekBatch.docs) {
          if (doc.id != docId) {
            throw 'Nomor batch "${drug.batch}" sudah terdaftar pada obat lain!';
          }
        }
      }

      await _db.collection('obat').doc(docId).update({
        'nama': drug.namaObat,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'harga_beli': drug.hargaBeli,
        'jumlah_stok': drug.totalStok,
        'barcode': drug.kodeBatang,
      });
      debugPrint('Obat berhasil diperbarui: ${drug.namaObat}');
    } catch (e) {
      debugPrint('Error saat mengupdate obat: $e');
      rethrow;
    }
  }

  static Future<void> ambilDataBatch(List<ModelObat> drugs) async {
    if (drugs.isEmpty) throw Exception('Daftar obat kosong');

    for (var drug in drugs) {
      if (drug.batch.isNotEmpty) {
        final cekBatch = await _db
            .collection('obat')
            .where('batch', isEqualTo: drug.batch)
            .get();

        if (cekBatch.docs.isNotEmpty) {
          throw 'Gagal! Nomor batch "${drug.batch}" pada obat ${drug.namaObat} sudah ada di database.';
        }
      }

      await _db.collection('obat').add({
        'nama': drug.namaObat,
        'batch': drug.batch,
        'exp_date': drug.expDate,
        'harga': drug.harga,
        'harga_beli': drug.hargaBeli,
        'jumlah_stok': drug.totalStok,
        'barcode': drug.kodeBatang,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<QuerySnapshot> alirkanDataObat() {
    return _db
        .collection('obat')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> catatTransaksiPenjualan(Penjualan penjualan) async {
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

  static Future<void> kurangiStokObat(
    String namaObat,
    String batch,
    int jumlah,
  ) async {
    try {
      debugPrint('Mengurangi stok: $namaObat ($batch) - $jumlah unit');

      final obatQuery = await _db
          .collection('obat')
          .where('nama', isEqualTo: namaObat)
          .where('batch', isEqualTo: batch)
          .get();

      if (obatQuery.docs.isNotEmpty) {
        final docId = obatQuery.docs.first.id;
        final currentStok =
            (obatQuery.docs.first.data()['jumlah_stok'] ?? 0) as num;
        final newStok = currentStok.toInt() - jumlah;

        if (newStok < 0) {
          throw 'Stok tidak mencukupi! Stok saat ini: $currentStok';
        }

        await _db.collection('obat').doc(docId).update({
          'jumlah_stok': newStok,
          'lastStockOpname': FieldValue.serverTimestamp(),
        });

        debugPrint('Stok $namaObat: $currentStok → $newStok');
      } else {
        throw Exception('Obat tidak ditemukan: $namaObat ($batch)');
      }
    } catch (e) {
      debugPrint('Error saat mengurangi stok: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> alirkanRiwayatPenjualan() {
    return _db
        .collection('penjualan')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> alirkanStokRealtime() {
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

  static Future<void> simpanObat(ModelObat drug) async {
    return tambahObatManual(drug);
  }

  static Future<void> hapusObat(String docId) async {
    try {
      debugPrint('Menghapus obat dengan ID: $docId');
      await _db.collection('obat').doc(docId).delete();
      debugPrint('Obat berhasil dihapus');
    } catch (e) {
      debugPrint('Error saat menghapus obat: $e');
      rethrow;
    }
  }
}
