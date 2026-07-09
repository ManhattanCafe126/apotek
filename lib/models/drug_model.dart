class ModelObat {
  final String idObat;
  final String namaObat;
  final String batch;
  final String expDate; // Format: DD/MM/YYYY
  final double harga; // Harga Jual
  final double hargaBeli; // Harga Beli
  final int totalStok;
  final String kodeBatang; // Barcode obat

  ModelObat({
    this.idObat = '',
    required this.namaObat,
    required this.batch,
    required this.expDate,
    required this.harga,
    required this.hargaBeli,
    required this.totalStok,
    this.kodeBatang = '',
  });

  factory ModelObat.fromJson(Map<String, dynamic> json) {
    return ModelObat(
      idObat: json['id']?.toString() ?? '',
      namaObat: json['nama']?.toString() ?? '',
      batch: json['batch']?.toString() ?? '',
      expDate: json['exp_date']?.toString() ?? '',
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
      hargaBeli: double.tryParse(json['harga_beli']?.toString() ?? '0') ?? 0.0,
      totalStok: int.tryParse(json['jumlah_stok']?.toString() ?? '0') ?? 0,
      kodeBatang: json['barcode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': idObat,
    'nama': namaObat,
    'batch': batch,
    'exp_date': expDate,
    'harga': harga,
    'harga_beli': hargaBeli,
    'jumlah_stok': totalStok,
    'barcode': kodeBatang,
  };

  @override
  String toString() =>
      'ModelObat(nama: $namaObat, batch: $batch, exp: $expDate, harga: $harga, hargaBeli: $hargaBeli, stok: $totalStok, barcode: $kodeBatang)';

  String get formattedHarga {
    if (harga <= 0) return '-';
    return harga.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String get formattedHargaBeli {
    if (hargaBeli <= 0) return '-';
    return hargaBeli.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String get formattedStok {
    if (totalStok <= 0) return '-';
    return totalStok.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class ModelBatch {
  final String nomorBatch;
  final DateTime tanggalKedaluwarsa;
  final int jumlah;

  ModelBatch({
    required this.nomorBatch,
    required this.tanggalKedaluwarsa,
    required this.jumlah,
  });

  factory ModelBatch.fromJson(Map<String, dynamic> json) {
    DateTime expDate;
    if (json['exp_date'] != null) {
      try {
        final parts = json['exp_date'].toString().split('/');
        if (parts.length == 3) {
          expDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          expDate = DateTime.now();
        }
      } catch (e) {
        expDate = DateTime.now();
      }
    } else {
      expDate = DateTime.now();
    }

    return ModelBatch(
      nomorBatch: json['batch']?.toString() ?? '',
      tanggalKedaluwarsa: expDate,
      jumlah: int.tryParse(json['jumlah_stok']?.toString() ?? '0') ?? 0,
    );
  }
}
