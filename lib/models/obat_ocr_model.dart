class ObatOCR {
  String nama;
  String batch;
  String expired;
  String? barcode;

  ObatOCR({
    required this.nama,
    required this.batch,
    required this.expired,
    this.barcode,
  });

  factory ObatOCR.fromJson(Map<String, dynamic> json) {
    return ObatOCR(
      nama: json['nama'] ?? '',
      batch: json['batch'] ?? '',
      expired: json['expired'] ?? '',
    );
  }
}