import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';

class LocalFoodEditScreen extends StatefulWidget {
  final FoodItem? food;

  final String name;
  final String kcal;
  final String khyd;
  final String fedt;
  final String prot;
  final String alk;

  const LocalFoodEditScreen({
    super.key,
    this.food,
    this.name = '',
    this.kcal = '',
    this.khyd = '',
    this.fedt = '',
    this.prot = '',
    this.alk = '0',
  });

  @override
  State<LocalFoodEditScreen> createState() => _LocalFoodEditScreenState();
}

class _LocalFoodEditScreenState extends State<LocalFoodEditScreen> {
  late TextEditingController nameController;
  late TextEditingController kcalController;
  late TextEditingController khydController;
  late TextEditingController protController;
  late TextEditingController fedtController;

  @override
  void initState() {
    super.initState();

    if (widget.food != null) {
      nameController = TextEditingController(text: widget.food!.navn);

      kcalController = TextEditingController(
        text: widget.food!.kcal.toString(),
      );

      khydController = TextEditingController(
        text: widget.food!.khyd.toString(),
      );

      protController = TextEditingController(
        text: widget.food!.prot.toString(),
      );

      fedtController = TextEditingController(
        text: widget.food!.fedt.toString(),
      );
    } else {
      nameController = TextEditingController(text: widget.name);

      kcalController = TextEditingController(text: widget.kcal);

      khydController = TextEditingController(text: widget.khyd);

      protController = TextEditingController(text: widget.prot);

      fedtController = TextEditingController(text: widget.fedt);
    }
  }

  double v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Widget line(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: TextField(controller: controller)),
        ],
      ),
    );
  }

  Future<void> saveFood() async {
    final food = FoodItem(
      navn: nameController.text.trim(),
      kcal: v(kcalController),
      khyd: v(khydController),
      prot: v(protController),
      fedt: v(fedtController),
      alk: 0,
    );

    if (widget.food == null) {
      await DatabaseService.instance.saveFoodToLocalAlias(
        alias: food.navn,
        food: food,
      );
    } else {
      await DatabaseService.instance.updateLocalFood(food);
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gemt')));
    }
  }

  Future<void> deleteFood() async {
    if (widget.food == null) return;

    await DatabaseService.instance.deleteLocalFood(widget.food!.navn);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indtast værdier for 100g'),
        backgroundColor: AppColors.brown,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              line('Fødevare', nameController),
              line('Kcal', kcalController),
              line('Kulhydrat', khydController),
              line('Protein', protController),
              line('Fedt', fedtController),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: saveFood,
                      child: const Text('Gem'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: deleteFood,
                      child: const Text('Slet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
