import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';
import 'local_food_edit_screen.dart';

class LocalFoodsScreen extends StatefulWidget {
  const LocalFoodsScreen({super.key});

  @override
  State<LocalFoodsScreen> createState() => _LocalFoodsScreenState();
}

class _LocalFoodsScreenState extends State<LocalFoodsScreen> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egne fødevarer'),
        backgroundColor: AppColors.brown,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Søg fødevare',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<FoodItem>>(
              future: DatabaseService.instance.getAllLocalFoods(),
              builder: (context, snapshot) {
                final allFoods = snapshot.data ?? [];

                final foods = allFoods.where((food) {
                  return food.navn.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  );
                }).toList();

                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];

                    return ListTile(
                      title: Text(food.navn),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocalFoodEditScreen(food: food),
                          ),
                        );
                        setState(() {});
                      },
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
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocalFoodEditScreen(),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('Tilføj fødevare'),
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
