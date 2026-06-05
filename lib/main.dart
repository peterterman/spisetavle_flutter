import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const SpiseTavleApp());
}

class SpiseTavleApp extends StatelessWidget {
  const SpiseTavleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpiseTavle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      home: const HomeScreen(),
    );
  }
}
