import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SalesItem {
  final String drugId;
  final String nama;
  final String batch;
  final double harga;
  final int jumlah;

  SalesItem({
    required this.drugId,
    required this.nama,
    required this.batch,
    required this.harga,
    required this.jumlah,
  });

  double get subtotal => harga * jumlah;

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'nama': nama,
      'batch': batch,
      'harga': harga,
      'jumlah': jumlah,
    };
  }

  factory SalesItem.fromMap(Map<String, dynamic> map) {
    return SalesItem(
      drugId: map['drugId'] ?? '',
      nama: map['nama'] ?? '',
      batch: map['batch'] ?? '',
      harga: (map['harga'] ?? 0).toDouble(),
      jumlah: map['jumlah'] ?? 0,
    );
  }
}

class Penjualan {
  final String id;
  final List<SalesItem> items;
  final Timestamp createdAt;

  Penjualan({required this.id, required this.items, required this.createdAt});

  double get total {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'createdAt': createdAt,
    };
  }

  factory Penjualan.fromMap(String id, Map<String, dynamic> map) {
    final itemsList = (map['items'] as List?) ?? [];
    final items = itemsList
        .map((item) => SalesItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return Penjualan(
      id: id,
      items: items,
      createdAt: map['createdAt'] as Timestamp,
    );
  }
}

/// Model untuk analisis tren penjualan obat
class AnalisisTren {
  final String namaObat;
  final double tren; // -1 = turun, 0 = sedang, 1 = naik
  final int totalPenjualanBulanIni;
  final int totalPenjualanBulanLalu;
  final int stokTerkini;
  final List<Map<String, dynamic>> stokDetail; // Untuk FEFO: {batch, exp_date, jumlah}

  AnalisisTren({
    required this.namaObat,
    required this.tren,
    required this.totalPenjualanBulanIni,
    required this.totalPenjualanBulanLalu,
    required this.stokTerkini,
    required this.stokDetail,
  });

  String getTrenLabel() {
    if (tren > 0.2) return 'Naik Drastis';
    if (tren > 0) return 'Naik';
    if (tren < -0.2) return 'Turun Drastis';
    if (tren < 0) return 'Turun';
    return 'Stabil';
  }

  /// Parse tanggal kedaluwarsa DD/MM/YYYY
  DateTime? _parseExpDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  /// Hitung hari tersisa sampai kedaluwarsa
  int? _daysUntilExpiry(String expDateStr) {
    final expDate = _parseExpDate(expDateStr);
    if (expDate == null) return null;
    return expDate.difference(DateTime.now()).inDays;
  }

  /// Ambil stok terdekat kedaluwarsa (FEFO First Expiry First Out)
  List<Map<String, dynamic>> getStokFEFO() {
    // Sort by expiry date (earliest first)
    final sorted = List<Map<String, dynamic>>.from(stokDetail);
    sorted.sort((a, b) {
      final daysA = _daysUntilExpiry(a['exp_date'] ?? '') ?? 999999;
      final daysB = _daysUntilExpiry(b['exp_date'] ?? '') ?? 999999;
      return daysA.compareTo(daysB);
    });
    return sorted;
  }

  /// Rekomendasi pembelian dengan logika FEFO
  String getRekomendasi() {
    final stokFEFO = getStokFEFO();

    // Cek stok akan kedaluwarsa dalam 30 hari (PRIORITAS UTAMA)
    final stokUrgent = stokFEFO
        .where((s) => (_daysUntilExpiry(s['exp_date'] ?? '') ?? 999999) <= 30)
        .toList();

    if (stokUrgent.isNotEmpty) {
      return 'Jual - ${stokUrgent.length} batch mendekati exp (FEFO)';
    }

    // Tren NAIK + stok MENIPIS → BELI
    if (tren > 0.15 && stokTerkini < 20) {
      return 'Beli - Tren naik, stok menipis';
    }

    // Stok SANGAT MENIPIS → BELI (regardless of trend)
    if (stokTerkini < 5) {
      return 'Beli - Stok sangat menipis (<5)';
    }

    // Tren TURUN → PERTAHANKAN (jangan beli)
    if (tren < -0.15) {
      return 'Pertahankan - Tren menurun, jangan beli';
    }

    // Tren SEDANG/STABIL
    if (tren >= -0.15 && tren <= 0.15) {
      if (stokTerkini < 15) {
        return 'Beli - Stok normal, persiapan pembelian';
      }
      return 'Pertahankan - Stok dan tren seimbang';
    }

    return 'Monitor - Kondisi normal';
  }

  Map<String, dynamic> toMap() => {
    'nama_obat': namaObat,
    'tren': tren,
    'penjualan_bulan_ini': totalPenjualanBulanIni,
    'penjualan_bulan_lalu': totalPenjualanBulanLalu,
    'stok_terkini': stokTerkini,
    'rekomendasi': getRekomendasi(),
  };
}
