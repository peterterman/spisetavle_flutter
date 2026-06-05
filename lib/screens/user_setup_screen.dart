import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/user_profile.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  static const brown = Color(0xffb29a7a);

  String brugerNr = 'bruger1';
  String sex = 'Kvinde';

  final nameController = TextEditingController();
  final kcalController = TextEditingController();
  final khydController = TextEditingController();
  final fedtController = TextEditingController();
  final protController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await DatabaseService.instance.getUserProfile(brugerNr);

    if (user == null) {
      nameController.clear();
      kcalController.clear();
      khydController.clear();
      fedtController.clear();
      protController.clear();
      weightController.clear();
      ageController.clear();
      sex = 'Kvinde';
    } else {
      nameController.text = user.name;
      kcalController.text = user.kcal.toStringAsFixed(0);
      khydController.text = user.khyd.toStringAsFixed(0);
      fedtController.text = user.fedt.toStringAsFixed(0);
      protController.text = user.prot.toStringAsFixed(0);
      weightController.text = user.weight.toStringAsFixed(0);
      ageController.text = user.age.toString();
      sex = user.sex;
    }

    setState(() {});
  }

  Future<void> saveUser() async {
    final user = UserProfile(
      brugerNr: brugerNr,
      name: nameController.text.trim(),
      kcal: double.tryParse(kcalController.text) ?? 0,
      khyd: double.tryParse(khydController.text) ?? 0,
      fedt: double.tryParse(fedtController.text) ?? 0,
      prot: double.tryParse(protController.text) ?? 0,
      weight: double.tryParse(weightController.text) ?? 0,
      age: int.tryParse(ageController.text) ?? 0,
      sex: sex,
    );

    await DatabaseService.instance.saveUserProfile(user);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bruger gemt')));

    Navigator.pop(context, true);
  }

  Widget inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: label == 'Navn'
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.65),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    kcalController.dispose();
    khydController.dispose();
    fedtController.dispose();
    protController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeee5d6),
      appBar: AppBar(
        title: const Text('Brugeropsætning'),
        backgroundColor: brown,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vælg bruger', style: TextStyle(fontSize: 22)),

              Row(
                children: [
                  Radio<String>(
                    value: 'bruger1',
                    groupValue: brugerNr,
                    onChanged: (value) {
                      setState(() => brugerNr = value!);
                      loadUser();
                    },
                  ),
                  const Text('Bruger 1', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 22),
                  Radio<String>(
                    value: 'bruger2',
                    groupValue: brugerNr,
                    onChanged: (value) {
                      setState(() => brugerNr = value!);
                      loadUser();
                    },
                  ),
                  const Text('Bruger 2', style: TextStyle(fontSize: 20)),
                ],
              ),

              const SizedBox(height: 12),

              inputField('Navn', nameController),
              inputField('Max KCAL', kcalController),
              inputField('Max Kulhydrat', khydController),
              inputField('Max Fedt', fedtController),
              inputField('Max Protein', protController),
              inputField('Vægt', weightController),
              inputField('Alder', ageController),

              const SizedBox(height: 10),
              const Text('Køn', style: TextStyle(fontSize: 22)),

              Row(
                children: [
                  Radio<String>(
                    value: 'Kvinde',
                    groupValue: sex,
                    onChanged: (value) {
                      setState(() => sex = value!);
                    },
                  ),
                  const Text('Kvinde', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 22),
                  Radio<String>(
                    value: 'Mand',
                    groupValue: sex,
                    onChanged: (value) {
                      setState(() => sex = value!);
                    },
                  ),
                  const Text('Mand', style: TextStyle(fontSize: 20)),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 14,
                      ),
                    ),
                    onPressed: saveUser,
                    child: const Text('Gem', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Fortryd',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
