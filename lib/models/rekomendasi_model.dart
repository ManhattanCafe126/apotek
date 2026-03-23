class RestockItem {
  final String nama;
  final String saran;
  final int jumlah;
  final String alasan;

  RestockItem({
    required this.nama,
    required this.saran,
    required this.jumlah,
    required this.alasan,
  });

  factory RestockItem.fromJson(Map<String, dynamic> json) {
    return RestockItem(
      nama: json['nama']?.toString() ?? '',
      saran: json['saran']?.toString() ?? '',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'saran': saran,
    'jumlah': jumlah,
    'alasan': alasan,
  };
}

class TidakRestockItem {
  final String nama;
  final String alasan;

  TidakRestockItem({
    required this.nama,
    required this.alasan,
  });

  factory TidakRestockItem.fromJson(Map<String, dynamic> json) {
    return TidakRestockItem(
      nama: json['nama']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'alasan': alasan,
  };
}
