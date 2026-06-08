class FoodItem {
  final int? id;
  final String navn;
  final double kcal;
  final double khyd;
  final double fedt;
  final double prot;
  final double alk;

  const FoodItem({
    this.id,
    required this.navn,
    required this.kcal,
    required this.khyd,
    required this.fedt,
    required this.prot,
    required this.alk,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['_id'] is int
          ? map['_id'] as int
          : int.tryParse(map['_id']?.toString() ?? ''),
      navn: map['name']?.toString() ?? '',
      kcal: _toDouble(map['kcal']),
      khyd: _toDouble(map['khyd']),
      fedt: _toDouble(map['fedt']),
      prot: _toDouble(map['prot']),
      alk: _toDouble(map['alk']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': navn,
      'kcal': kcal.toString(),
      'khyd': khyd.toString(),
      'fedt': fedt.toString(),
      'prot': prot.toString(),
      'alk': alk.toString(),
    };
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
