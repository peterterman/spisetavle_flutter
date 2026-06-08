class UserProfile {
  final String brugerNr;
  final String name;
  final double kcal;
  final double khyd;
  final double fedt;
  final double prot;
  final double weight;
  final int age;
  final String sex;

  UserProfile({
    required this.brugerNr,
    required this.name,
    required this.kcal,
    required this.khyd,
    required this.fedt,
    required this.prot,
    required this.weight,
    required this.age,
    required this.sex,
  });

  Map<String, dynamic> toMap() {
    return {
      'bruger_nr': brugerNr,
      'name': name,
      'kcal': kcal.toString(),
      'khyd': khyd.toString(),
      'fedt': fedt.toString(),
      'prot': prot.toString(),
      'weight': weight.toString(),
      'age': age.toString(),
      'sex': sex,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      brugerNr: map['bruger_nr'].toString(),
      name: map['name'].toString(),
      kcal: double.tryParse(map['kcal'].toString()) ?? 0,
      khyd: double.tryParse(map['khyd'].toString()) ?? 0,
      fedt: double.tryParse(map['fedt'].toString()) ?? 0,
      prot: double.tryParse(map['prot'].toString()) ?? 0,
      weight: double.tryParse(map['weight'].toString()) ?? 0,
      age: int.tryParse(map['age'].toString()) ?? 0,
      sex: map['sex'].toString(),
    );
  }
}
