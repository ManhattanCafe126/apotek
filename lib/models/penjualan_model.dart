import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ItemPenjualan {
  final String drugId;
  final String nama;
  final String batch;
  final double harga;
  final int jumlah;

  ItemPenjualan({
    required this.drugId,
    required this.nama,
    required this.batch,
    required this.harga,
    required this.jumlah,
  });

  double get subtotal => harga * jumlah;

  Map<String, dynamic> keMap() {
    return {
      'drugId': drugId,
      'nama': nama,
      'batch': batch,
      'harga': harga,
      'jumlah': jumlah,
    };
  }

  factory ItemPenjualan.dariMap(Map<String, dynamic> map) {
    return ItemPenjualan(
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
  final List<ItemPenjualan> items;
  final Timestamp createdAt;

  Penjualan({required this.id, required this.items, required this.createdAt});

  double get total {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  Map<String, dynamic> keMap() {
    return {
      'items': items.map((item) => item.keMap()).toList(),
      'total': total,
      'createdAt': createdAt,
    };
  }

  factory Penjualan.dariMap(String id, Map<String, dynamic> map) {
    final itemsList = (map['items'] as List?) ?? [];
    final items = itemsList
        .map((item) => ItemPenjualan.dariMap(item as Map<String, dynamic>))
        .toList();

    return Penjualan(
      id: id,
      items: items,
      createdAt: map['createdAt'] as Timestamp,
    );
  }
}

class AnalisisTren {
  final String namaObat;
  final double tren;
  final int totalPenjualanBulanIni;
  final int totalPenjualanBulanLalu;
  final int stokTerkini;
  final List<Map<String, dynamic>> stokDetail;

  AnalisisTren({
    required this.namaObat,
    required this.tren,
    required this.totalPenjualanBulanIni,
    required this.totalPenjualanBulanLalu,
    required this.stokTerkini,
    required this.stokDetail,
  });

  String dapatkanLabelTren() {
    if (tren > 0.2) return 'Naik Drastis';
    if (tren > 0) return 'Naik';
    if (tren < -0.2) return 'Turun Drastis';
    if (tren < 0) return 'Turun';
    return 'Stabil';
  }

  DateTime? _parsirTanggalExp(String dateStr) {
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

  int? _hariHinggaKadaluarsa(String expDateStr) {
    final expDate = _parsirTanggalExp(expDateStr);
    if (expDate == null) return null;
    return expDate.difference(DateTime.now()).inDays;
  }

  List<Map<String, dynamic>> dapatkanStokFEFO() {
    final sorted = List<Map<String, dynamic>>.from(stokDetail);
    sorted.sort((a, b) {
      final daysA = _hariHinggaKadaluarsa(a['exp_date'] ?? '') ?? 999999;
      final daysB = _hariHinggaKadaluarsa(b['exp_date'] ?? '') ?? 999999;
      return daysA.compareTo(daysB);
    });
    return sorted;
  }

  String dapatkanRekomendasi() {
    final stokFEFO = dapatkanStokFEFO();
    final stokUrgent = stokFEFO
        .where((s) => (_hariHinggaKadaluarsa(s['exp_date'] ?? '') ?? 999999) <= 30)
        .toList();

    if (stokUrgent.isNotEmpty) {
      return 'Jual - ${stokUrgent.length} batch mendekati exp (FEFO)';
    }
    if (tren > 0.15 && stokTerkini < 20) {
      return 'Beli - Tren naik, stok menipis';
    }
    if (stokTerkini < 5) {
      return 'Beli - Stok sangat menipis (<5)';
    }
    if (tren < -0.15) {
      return 'Pertahankan - Tren menurun, jangan beli';
    }
    if (tren >= -0.15 && tren <= 0.15) {
      if (stokTerkini < 15) {
        return 'Beli - Stok normal, persiapan pembelian';
      }
      return 'Pertahankan - Stok dan tren seimbang';
    }

    return 'Monitor - Kondisi normal';
  }

  Map<String, dynamic> keMap() => {
    'nama_obat': namaObat,
    'tren': tren,
    'penjualan_bulan_ini': totalPenjualanBulanIni,
    'penjualan_bulan_lalu': totalPenjualanBulanLalu,
    'stok_terkini': stokTerkini,
    'rekomendasi': dapatkanRekomendasi(),
  };
}
