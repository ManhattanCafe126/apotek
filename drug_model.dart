class DrugData {
  final String nama;
  final String batch;
  final String expDate; // Format: DD/MM/YYYY
  final double harga;
  final int jumlahStok;
  final String barcode; // Barcode obat

  DrugData({
    required this.nama,
    required this.batch,
    required this.expDate,
    required this.harga,
    required this.jumlahStok,
    this.barcode = '',
  });

  factory DrugData.fromJson(Map<String, dynamic> json) {
    return DrugData(
      nama: json['nama']?.toString() ?? '',
      batch: json['batch']?.toString() ?? '',
      expDate: json['exp_date']?.toString() ?? '',
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
      jumlahStok: int.tryParse(json['jumlah_stok']?.toString() ?? '0') ?? 0,
      barcode: json['barcode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'batch': batch,
    'exp_date': expDate,
    'harga': harga,
    'jumlah_stok': jumlahStok,
    'barcode': barcode,
  };

  @override
  String toString() =>
      'DrugData(nama: $nama, batch: $batch, exp: $expDate, harga: $harga, stok: $jumlahStok, barcode: $barcode)';
}
