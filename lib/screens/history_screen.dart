import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../theme/app_colors.dart';
import 'day_view_screen.dart';

class HistoryScreen extends StatelessWidget {
  final String user;
  final String userName;

  const HistoryScreen({super.key, required this.user, required this.userName});

  String value(Object? v) {
    final n = double.tryParse(v?.toString() ?? '') ?? 0;
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Historik - $userName'),
        backgroundColor: AppColors.brown,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: DatabaseService.instance.getHistoryTotals(
          user,
          userName: userName,
        ),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? [];

          if (rows.isEmpty) {
            return const Center(child: Text('Ingen historik'));
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Dato')),
                    Expanded(child: Text('Kulh.', textAlign: TextAlign.right)),
                    Expanded(child: Text('Fedt', textAlign: TextAlign.right)),
                    Expanded(child: Text('Prot.', textAlign: TextAlign.right)),
                    Expanded(child: Text('Kcal', textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];

                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayViewScreen(
                              user: user,
                              date: row['date'].toString(),
                              userName: userName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(row['date'].toString()),
                            ),
                            Expanded(
                              child: Text(
                                value(row['khyd']),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                value(row['fedt']),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                value(row['prot']),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                value(row['kcal']),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
