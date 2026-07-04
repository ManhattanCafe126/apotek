class ItemRestok {
  final String nama;
  final String saran;
  final int jumlah;
  final String alasan;

  ItemRestok({
    required this.nama,
    required this.saran,
    required this.jumlah,
    required this.alasan,
  });

  factory ItemRestok.dariJson(Map<String, dynamic> json) {
    return ItemRestok(
      nama: json['nama']?.toString() ?? '',
      saran: json['saran']?.toString() ?? '',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> keMap() => {
    'nama': nama,
    'saran': saran,
    'jumlah': jumlah,
    'alasan': alasan,
  };
}

class ItemTidakRestok {
  final String nama;
  final String alasan;

  ItemTidakRestok({
    required this.nama,
    required this.alasan,
  });

  factory ItemTidakRestok.dariJson(Map<String, dynamic> json) {
    return ItemTidakRestok(
      nama: json['nama']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> keMap() => {
    'nama': nama,
    'alasan': alasan,
  };
}
