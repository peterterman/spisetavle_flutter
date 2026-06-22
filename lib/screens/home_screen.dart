import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_service.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/nutrient_row.dart';
import 'day_view_screen.dart';
import 'history_screen.dart';
import 'input_screen.dart';
import 'user_setup_screen.dart';
import 'local_foods_screen.dart';
import 'meals_screen.dart';
import 'dart:io';
import 'barcode_scan_screen.dart';
import 'local_food_edit_screen.dart';
import '../services/barcode_service.dart';
import 'calorie_calculator_screen.dart';
import 'meal_photo_screen.dart';
import 'ai_match_screen.dart';
import 'package:url_launcher/url_launcher.dart';

int streak = 0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 2);

  String selectedBrugerNr = 'bruger1';
  UserProfile? currentUser;

  String user1Name = 'Bruger 1';
  String user2Name = 'Bruger 2';

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Kunne ikke åbne $url');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void showAboutDialogSpiseTavle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Datakilder og information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Version 3.0 - Flutter\n\n'
                'Udviklet af Peter Terman Hansen',
              ),

              const SizedBox(height: 16),

              const Text(
                'Datakilder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              TextButton(
                onPressed: () => _openUrl('https://frida.fooddata.dk'),
                child: const Text('FRIDA Fødevaredatabasen'),
              ),

              const Text(
                'Version 5.4 (2025)\n'
                'DTU Fødevareinstituttet\n'
                'Danmarks Tekniske Universitet',
              ),

              const SizedBox(height: 16),

              const Text(
                'Beregninger',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const Text(
                'Kalorier, protein, fedt og kulhydrater beregnes på baggrund af de registrerede fødevarer og værdierne i FRIDA-databasen.',
              ),

              const SizedBox(height: 16),

              const Text(
                'Ansvarsfraskrivelse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const Text(
                'SpiseTavle er et informationsværktøj til registrering af kost og næringsindtag.\n\n'
                'Appen er ikke medicinsk udstyr og erstatter ikke rådgivning fra læge, diætist eller andre sundhedsfaglige personer.',
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => _openUrl('https://toft-terman.dk/spisetavle'),
                child: const Text('Support'),
              ),

              TextButton(
                onPressed: () => _openUrl('https://toft-terman.dk/privacy'),
                child: const Text('Privatlivspolitik'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> loadUser() async {
    final user = await DatabaseService.instance.getUserProfile(
      selectedBrugerNr,
    );
    final u1 = await DatabaseService.instance.getUserProfile('bruger1');
    final u2 = await DatabaseService.instance.getUserProfile('bruger2');

    if (!mounted) return;

    setState(() {
      currentUser = user;
      user1Name = (u1?.name.trim().isNotEmpty ?? false) ? u1!.name : 'Bruger 1';
      user2Name = (u2?.name.trim().isNotEmpty ?? false) ? u2!.name : 'Bruger 2';
    });

    final userStreak = await DatabaseService.instance.getStreak(
      selectedBrugerNr,
    );
    streak = userStreak;
  }

  DateTime dateForPage(int pageIndex) {
    return DateTime.now().subtract(Duration(days: 2 - pageIndex));
  }

  String dateText(int pageIndex) {
    final date = dateForPage(pageIndex);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day $month $year';
  }

  String dayLabel(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 'I forgårs';
      case 1:
        return 'I går';
      case 2:
        return 'I dag';
      default:
        return '';
    }
  }

  String goal(double? value) {
    if (value == null) return '0';
    return value.toStringAsFixed(0);
  }

  Future<void> openUserSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSetupScreen()),
    );

    await loadUser();
  }

  Widget roundButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: AppColors.brown,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget buildDayPage(
    BuildContext context,
    BoxConstraints constraints,
    int pageIndex,
  ) {
    final name = currentUser?.name.trim().isNotEmpty == true
        ? currentUser!.name
        : 'Ingen bruger';

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 18, 18),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        dateText(pageIndex),
                        style: TextStyle(fontSize: AppSizes.title),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabel(pageIndex),
                        style: TextStyle(
                          fontSize: AppSizes.small,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: TextStyle(fontSize: AppSizes.heading)),
                const SizedBox(height: 10),
                FutureBuilder<int>(
                  future: DatabaseService.instance.getStreakForDate(
                    selectedBrugerNr,
                    dateText(pageIndex),
                  ),
                  builder: (context, snapshot) {
                    final streak = snapshot.data ?? 0;

                    return Text(
                      'Streak: $streak dage',
                      style: TextStyle(
                        fontSize: AppSizes.normal,
                        color: Colors.black54,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FutureBuilder<Map<String, double>>(
                  future: DatabaseService.instance.getDailyTotals(
                    selectedBrugerNr,
                    dateText(pageIndex),
                  ),
                  builder: (context, snapshot) {
                    final totals = snapshot.data ?? {};

                    final totalKhyd = totals['khyd'] ?? 0;
                    final totalFedt = totals['fedt'] ?? 0;
                    final totalProt = totals['prot'] ?? 0;
                    final totalKcal = totals['kcal'] ?? 0;

                    return Column(
                      children: [
                        NutrientRow(
                          name: 'Kulh.',
                          value: totalKhyd.toStringAsFixed(0),
                          goal: goal(currentUser?.khyd),
                          progress:
                              currentUser == null || currentUser!.khyd == 0
                              ? 0
                              : totalKhyd / currentUser!.khyd,
                        ),
                        NutrientRow(
                          name: 'Fedt',
                          value: totalFedt.toStringAsFixed(0),
                          goal: goal(currentUser?.fedt),
                          progress:
                              currentUser == null || currentUser!.fedt == 0
                              ? 0
                              : totalFedt / currentUser!.fedt,
                        ),
                        NutrientRow(
                          name: 'Prot.',
                          value: totalProt.toStringAsFixed(0),
                          goal: goal(currentUser?.prot),
                          progress:
                              currentUser == null || currentUser!.prot == 0
                              ? 0
                              : totalProt / currentUser!.prot,
                        ),
                        NutrientRow(
                          name: 'Kcal',
                          value: totalKcal.toStringAsFixed(0),
                          goal: goal(currentUser?.kcal),
                          progress:
                              currentUser == null || currentUser!.kcal == 0
                              ? 0
                              : totalKcal / currentUser!.kcal,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Radio<String>(
                      value: 'bruger1',
                      groupValue: selectedBrugerNr,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedBrugerNr = value;
                        });
                        loadUser();
                      },
                    ),
                    Text(
                      user1Name,
                      style: TextStyle(fontSize: AppSizes.normal),
                    ),
                    const SizedBox(width: 24),
                    Radio<String>(
                      value: 'bruger2',
                      groupValue: selectedBrugerNr,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedBrugerNr = value;
                        });
                        loadUser();
                      },
                    ),
                    Text(
                      user2Name,
                      style: TextStyle(fontSize: AppSizes.normal),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    roundButton(
                      heroTag: 'input_$pageIndex',
                      icon: Icons.add_box,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InputScreen(
                              user: selectedBrugerNr,
                              date: dateText(pageIndex),
                              userName: currentUser?.name ?? '',
                            ),
                          ),
                        );

                        if (result == true) {
                          setState(() {});
                        }
                      },
                    ),
                    roundButton(
                      heroTag: 'dayview_$pageIndex',
                      icon: Icons.calendar_month,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayViewScreen(
                              user: selectedBrugerNr,
                              date: dateText(pageIndex),
                              userName: currentUser?.name ?? '',
                            ),
                          ),
                        );

                        setState(() {});
                      },
                    ),
                    roundButton(
                      heroTag: 'history_$pageIndex',
                      icon: Icons.history,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryScreen(
                              user: selectedBrugerNr,
                              userName: currentUser?.name ?? selectedBrugerNr,
                            ),
                          ),
                        );

                        setState(() {});
                      },
                    ),
                  ],
                ),
                const Spacer(),

                if (Platform.isAndroid)
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: AppSizes.heading,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> scanFood() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );

    if (!mounted) return;
    if (barcode == null) return;

    final food = await BarcodeService.getFood(barcode);
    if (!mounted) return;

    if (food == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fødevare ikke fundet')));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalFoodEditScreen(
          name: food['name']?.toString() ?? '',
          kcal: food['kcal']?.toString() ?? '',
          khyd: food['carbs']?.toString() ?? '',
          fedt: food['fat']?.toString() ?? '',
          prot: food['protein']?.toString() ?? '',
          alk: '0',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SpiseTavle',
          style: TextStyle(
            fontSize: AppSizes.title + 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brown,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'calorie') {

                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalorieCalculatorScreen(),
                  ),
                );

                if (changed == true) {
                  await loadUser();
                  setState(() {});
                }
                await loadUser();
              }
              if (value == 'users') {
                await openUserSetup();
              }
              if (value == 'localfoods') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocalFoodsScreen()),
                );
              }
              if (value == 'scanfood') {
                await scanFood();
              }
              if (value == 'about') {
                showAboutDialogSpiseTavle();
              }
              if (value == 'meals') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealsScreen()),
                );
                setState(() {});
              }
              if (value == 'analyser_maaltid') {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealPhotoScreen(
                      user: selectedBrugerNr,
                      date: dateText(2),
                      userName: currentUser?.name ?? '',
                    ),
                  ),
                );

                if (changed == true) {
                  setState(() {});
                }
              }
              if (value == 'test_ai') {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AiMatchScreen(aiFood: 'grillet kylling'),
                  ),
                );

                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Valgt: $result')));
                }
              }
            },
            itemBuilder: (context) => [
              if (true)
                PopupMenuItem(
                  value: 'analyser_maaltid',
                  child: Text('Analyser måltid'),
                ),
              const PopupMenuItem(
                value: 'scanfood',
                child: Text('Scan fødevare'),
              ),
              PopupMenuItem(value: 'localfoods', child: Text('Egne fødevarer')),
              PopupMenuItem(value: 'meals', child: Text('Måltider')),
              PopupMenuItem(value: 'users', child: Text('Brugeropsætning')),
              PopupMenuItem(value: 'calorie', child: Text('Kalorieberegner')),
              PopupMenuItem(
                value: 'about',
                child: Text('Datakilder og information'),
              ),
            ],
          ),
        ],
        toolbarHeight: 64,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return PageView.builder(
              controller: _pageController,
              itemCount: 3,
              itemBuilder: (context, pageIndex) {
                return buildDayPage(context, constraints, pageIndex);
              },
            );
          },
        ),
      ),
    );
  }
}
