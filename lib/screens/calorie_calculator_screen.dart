import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() =>
      _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  String brugerNr = 'bruger1';
  String sex = 'Mand';
  String activity = 'Stillesiddende';
  String goal = 'Vedligehold';
  bool keto = false;

  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  double kcal = 0;
  double khyd = 0;
  double fedt = 0;
  double prot = 0;

  double activityFactor() {
    switch (activity) {
      case 'Let aktiv':
        return 1.375;
      case 'Moderat aktiv':
        return 1.55;
      case 'Meget aktiv':
        return 1.725;
      default:
        return 1.2;
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void calculate() {
    final age = double.tryParse(ageController.text.replaceAll(',', '.')) ?? 0;
    final weight =
        double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0;
    final height =
        double.tryParse(heightController.text.replaceAll(',', '.')) ?? 0;

    if (age == 0 || weight == 0 || height == 0) return;

    double bmr = 10 * weight + 6.25 * height - 5 * age;

    if (sex == 'Mand') {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    double resultKcal = bmr * activityFactor();

    if (goal == 'Tabe 0.5 kg/uge') {
      resultKcal -= 500;
    }

    if (goal == 'Tabe 1 kg/uge') {
      resultKcal -= 1000;
    }

    if (resultKcal < 1000) resultKcal = 1000;

    final resultProt = weight * 1.7;
    double resultKhyd;
    double resultFedt;

    if (keto) {
      resultKhyd = 25;
      resultFedt = (resultKcal - resultProt * 4 - resultKhyd * 4) / 9;
    } else {
      resultFedt = (resultKcal * 0.30) / 9;
      resultKhyd = (resultKcal - resultProt * 4 - resultFedt * 9) / 4;
    }

    setState(() {
      kcal = resultKcal;
      prot = resultProt;
      fedt = resultFedt;
      khyd = resultKhyd;
    });
  }

  String normalizeSex(String value) {
    final s = value.trim().toLowerCase();

    if (s == 'mand' || s == 'm') return 'Mand';
    if (s == 'kvinde' || s == 'k') return 'Kvinde';

    return 'Mand';
  }

  Future<void> loadUser() async {
    final user = await DatabaseService.instance.getUserProfile(brugerNr);

    if (user == null) return;

    setState(() {
      sex = normalizeSex(user.sex);

      ageController.text = user.age == 0 ? '' : user.age.toString();

      weightController.text = user.weight == 0
          ? ''
          : user.weight.toStringAsFixed(0);

      kcal = user.kcal;
      khyd = user.khyd;
      fedt = user.fedt;
      prot = user.prot;
    });
  }

  Future<void> saveToUser() async {
    final oldUser = await DatabaseService.instance.getUserProfile(brugerNr);

    final user = UserProfile(
      brugerNr: brugerNr,
      name: oldUser?.name ?? '',
      kcal: kcal,
      khyd: khyd,
      fedt: fedt,
      prot: prot,
      weight:
          double.tryParse(weightController.text.replaceAll(',', '.')) ??
          oldUser?.weight ??
          0,
      age: int.tryParse(ageController.text) ?? oldUser?.age ?? 0,
      sex: sex,
    );

    await DatabaseService.instance.saveUserProfile(user);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bruger gemt')));

    Navigator.pop(context, true);
  }

  Widget input(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(fontSize: AppSizes.normal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalorieberegner'),
        backgroundColor: AppColors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RadioListTile(
              title: const Text('Bruger 1'),
              value: 'bruger1',
              groupValue: brugerNr,
              onChanged: (v) => setState(() => brugerNr = v!),
            ),
            RadioListTile(
              title: const Text('Bruger 2'),
              value: 'bruger2',
              groupValue: brugerNr,
              onChanged: (v) => setState(() => brugerNr = v!),
            ),
            input('Alder', ageController),
            input('Vægt kg', weightController),
            input('Højde cm', heightController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sex,
              decoration: const InputDecoration(labelText: 'Køn'),
              items: const [
                DropdownMenuItem(value: 'Mand', child: Text('Mand')),
                DropdownMenuItem(value: 'Kvinde', child: Text('Kvinde')),
              ],
              onChanged: (v) => setState(() => sex = v!),
            ),
            DropdownButtonFormField<String>(
              value: activity,
              decoration: const InputDecoration(labelText: 'Aktivitetsniveau'),
              items: const [
                DropdownMenuItem(
                  value: 'Stillesiddende',
                  child: Text('Stillesiddende'),
                ),
                DropdownMenuItem(value: 'Let aktiv', child: Text('Let aktiv')),
                DropdownMenuItem(
                  value: 'Moderat aktiv',
                  child: Text('Moderat aktiv'),
                ),
                DropdownMenuItem(
                  value: 'Meget aktiv',
                  child: Text('Meget aktiv'),
                ),
              ],
              onChanged: (v) => setState(() => activity = v!),
            ),
            CheckboxListTile(
              title: const Text('Keto'),
              value: keto,
              onChanged: (v) => setState(() => keto = v ?? false),
            ),
            DropdownButtonFormField<String>(
              value: goal,
              decoration: const InputDecoration(labelText: 'Vælg beregning'),
              items: const [
                DropdownMenuItem(
                  value: 'Vedligehold',
                  child: Text('Vedligehold vægt'),
                ),
                DropdownMenuItem(
                  value: 'Tabe 0.5 kg/uge',
                  child: Text('Tabe 0.5 kg/uge'),
                ),
                DropdownMenuItem(
                  value: 'Tabe 1 kg/uge',
                  child: Text('Tabe 1 kg/uge'),
                ),
              ],
              onChanged: (v) => setState(() => goal = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: calculate, child: const Text('Beregn')),
            const SizedBox(height: 20),
            Text('Kcal: ${kcal.toStringAsFixed(0)}'),
            Text('Kulhydrat: ${khyd.toStringAsFixed(0)} g'),
            Text('Fedt: ${fedt.toStringAsFixed(0)} g'),
            Text('Protein: ${prot.toStringAsFixed(0)} g'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: kcal > 0 ? saveToUser : null,
              child: const Text('Gem til bruger'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
