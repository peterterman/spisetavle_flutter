class LogEntry {
  final int? id;
  final String date;
  final String name;
  final double amount;
  final double kcal;
  final double khyd;
  final double fedt;
  final double prot;
  final double alk;
  final String user;
  final String? tid;

  LogEntry({
    this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.kcal,
    required this.khyd,
    required this.fedt,
    required this.prot,
    required this.alk,
    required this.user,
    this.tid,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'date': date,
      'name': name,
      'amount': amount,
      'kcal': kcal.toString(),
      'khyd': khyd.toString(),
      'fedt': fedt.toString(),
      'prot': prot.toString(),
      'alk': alk.toString(),
      'user': user,
      'tid': tid,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['_id'],
      date: map['date'].toString(),
      name: map['name'].toString(),
      amount: double.tryParse(map['amount'].toString()) ?? 0,
      kcal: double.tryParse(map['kcal'].toString()) ?? 0,
      khyd: double.tryParse(map['khyd'].toString()) ?? 0,
      fedt: double.tryParse(map['fedt'].toString()) ?? 0,
      prot: double.tryParse(map['prot'].toString()) ?? 0,
      alk: double.tryParse(map['alk'].toString()) ?? 0,
      user: map['user'].toString(),
      tid: map['tid']?.toString(),
    );
  }
}
