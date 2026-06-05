import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../theme/app_colors.dart';

class DayViewScreen extends StatelessWidget {
  final String user;
  final String date;
  final String? userName;

  const DayViewScreen({
    super.key,
    required this.user,
    required this.date,
    this.userName,
  });

  Future<List<Map<String, Object?>>> load(String tid) {
    return DatabaseService.instance.getLogForMealTime(
      user: user,
      date: date,
      tid: tid,
    );
  }

  String value(Object? v) {
    final n = double.tryParse(v?.toString().replaceAll(',', '.') ?? '') ?? 0;

    if (n == n.roundToDouble()) {
      return n.toStringAsFixed(0);
    }

    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  Widget headerRow() {
    const hStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

    return const Row(
      children: [
        Expanded(child: Text('Mad', style: hStyle)),
        SizedBox(
          width: 52,
          child: Text('Gram', textAlign: TextAlign.right, style: hStyle),
        ),
        SizedBox(
          width: 56,
          child: Text('Kcal', textAlign: TextAlign.right, style: hStyle),
        ),
        SizedBox(
          width: 50,
          child: Text('Kulh', textAlign: TextAlign.right, style: hStyle),
        ),
        SizedBox(
          width: 50,
          child: Text('Prot', textAlign: TextAlign.right, style: hStyle),
        ),
        SizedBox(
          width: 50,
          child: Text('Fedt', textAlign: TextAlign.right, style: hStyle),
        ),
      ],
    );
  }

  Widget dataRow(Map<String, Object?> row) {
    const rowStyle = TextStyle(fontSize: 15);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row['name'].toString(),
              overflow: TextOverflow.ellipsis,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              value(row['amount']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              value(row['kcal']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(row['khyd']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(row['prot']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(row['fedt']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> sumRows(List<Map<String, Object?>> rows) {
    double kcal = 0;
    double khyd = 0;
    double prot = 0;
    double fedt = 0;

    for (final row in rows) {
      kcal +=
          double.tryParse(row['kcal']?.toString().replaceAll(',', '.') ?? '') ??
          0;
      khyd +=
          double.tryParse(row['khyd']?.toString().replaceAll(',', '.') ?? '') ??
          0;
      prot +=
          double.tryParse(row['prot']?.toString().replaceAll(',', '.') ?? '') ??
          0;
      fedt +=
          double.tryParse(row['fedt']?.toString().replaceAll(',', '.') ?? '') ??
          0;
    }

    return {'kcal': kcal, 'khyd': khyd, 'prot': prot, 'fedt': fedt};
  }

  Widget sumRow(List<Map<String, Object?>> rows) {
    final sums = sumRows(rows);
    const rowStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Expanded(child: Text('Sum', style: rowStyle)),
          const SizedBox(width: 52),
          SizedBox(
            width: 56,
            child: Text(
              value(sums['kcal']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(sums['khyd']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(sums['prot']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value(sums['fedt']),
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget mealSection(String title, String tid) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: load(tid),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 8),
              ...rows.map(dataRow),
              sumRow(rows),
              const Divider(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = userName == null || userName!.trim().isEmpty
        ? date
        : '$date - $userName';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 18),
              headerRow(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    mealSection('Morgen', 'm'),
                    mealSection('Frokost', 'f'),
                    mealSection('Aften', 'a'),
                    mealSection('Snack', 's'),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 42,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
