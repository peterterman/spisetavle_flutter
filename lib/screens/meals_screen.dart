import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../theme/app_colors.dart';
import 'meal_edit_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  Future<void> openMeal(String mealName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealEditScreen(mealName: mealName)),
    );

    setState(() {});
  }

  Future<void> addMeal() async {
    final controller = TextEditingController();

    final mealName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nyt måltid'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Måltidsnavn'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fortryd'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (mealName == null || mealName.isEmpty) return;

    await openMeal(mealName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Måltider'),
        backgroundColor: AppColors.brown,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<String>>(
              future: DatabaseService.instance.getAllMeals(),
              builder: (context, snapshot) {
                final meals = snapshot.data ?? [];

                if (meals.isEmpty) {
                  return const Center(child: Text('Ingen måltider'));
                }

                return ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];

                    return ListTile(
                      title: Text(meal),
                      onTap: () => openMeal(meal),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brown,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: addMeal,
                    child: const Text('Tilføj måltid'),
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
                    child: const Text('Færdig'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
