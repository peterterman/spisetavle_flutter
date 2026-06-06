import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class MealEditScreen extends StatefulWidget {
  final String mealName;

  const MealEditScreen({super.key, required this.mealName});

  @override
  State<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends State<MealEditScreen> {
  final foodController = TextEditingController();
  final amountController = TextEditingController();

  String value(Object? v) {
    final n = double.tryParse(v?.toString().replaceAll(',', '.') ?? '') ?? 0;
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  double readAmount() {
    return double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
  }

  Future<FoodItem?> chooseFridaFood(String typedText) async {
    final matches = await DatabaseService.instance.searchFridaFoodItems(
      typedText,
    );

    if (!mounted) return null;

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingen Frida-match for "$typedText"')),
      );
      return null;
    }

    return showDialog<FoodItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vælg Frida-post for "$typedText"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final food = matches[index];

              return ListTile(
                dense: true,
                title: Text(food.navn),
                subtitle: Text(
                  'Kcal ${food.kcal.toStringAsFixed(0)}  '
                  'Kulh ${food.khyd.toStringAsFixed(1)}  '
                  'Prot ${food.prot.toStringAsFixed(1)}  '
                  'Fedt ${food.fedt.toStringAsFixed(1)}',
                ),
                onTap: () => Navigator.pop(context, food),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Afvis'),
          ),
        ],
      ),
    );
  }

  Future<void> addFoodToMeal() async {
    final typedName = foodController.text.trim();
    final amount = readAmount();

    if (typedName.isEmpty || amount <= 0) return;

    final forceFrida = typedName.startsWith('#');
    final alias = forceFrida ? typedName.substring(1).trim() : typedName;

    if (alias.isEmpty) return;

    FoodItem? food;

    if (!forceFrida) {
      food = await DatabaseService.instance.getLocalFoodExact(alias);
    }

    if (food == null) {
      final selected = await chooseFridaFood(typedName);
      if (selected == null) return;

      food = selected;

      if (!forceFrida) {
        await DatabaseService.instance.saveFoodToLocalAlias(
          alias: alias,
          food: selected,
        );
      }
    }

    await DatabaseService.instance.insertMealItem(
      mealName: widget.mealName,
      displayName: forceFrida ? food.navn : alias,
      amount: amount,
      food: food,
    );

    foodController.clear();
    amountController.clear();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> editItem(Map<String, Object?> row) async {
    final rowid = int.tryParse(row['rowid']?.toString() ?? '');

    if (rowid != null) {
      await DatabaseService.instance.deleteMealItem(rowid);
    }

    foodController.text = row['name']?.toString() ?? '';
    amountController.text = value(row['amount']);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> deleteItem(int rowid) async {
    await DatabaseService.instance.deleteMealItem(rowid);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> deleteWholeMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet måltid?'),
        content: Text('Vil du slette "${widget.mealName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nej'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DatabaseService.instance.deleteMeal(widget.mealName);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget headerRow() {
    final style = TextStyle(
      fontSize: AppSizes.normal,
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        SizedBox(width: 44),
        Expanded(child: Text('Mad', style: style)),
        SizedBox(
          width: 52,
          child: Text('Gram', textAlign: TextAlign.right, style: style),
        ),
        SizedBox(
          width: 56,
          child: Text('Kcal', textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }

  Widget dataRow(Map<String, Object?> row) {
    final rowid = int.tryParse(row['rowid']?.toString() ?? '') ?? -1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
              ),
              onPressed: rowid < 0 ? null : () => editItem(row),
              child: const Icon(Icons.close, size: 22),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => editItem(row),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  row['name']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: AppSizes.normal),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: InkWell(
              onTap: () => editItem(row),
              child: Text(
                value(row['amount']),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: AppSizes.normal),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: InkWell(
              onTap: () => editItem(row),
              child: Text(
                value(row['kcal']),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: AppSizes.normal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mealList() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: DatabaseService.instance.getMealItems(widget.mealName),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return const Center(child: Text('Ingen fødevarer i måltidet'));
        }

        return ListView(
          children: [
            headerRow(),
            const Divider(height: 8),
            ...rows.map(dataRow),
          ],
        );
      },
    );
  }

  Widget inputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: foodController,
                decoration: const InputDecoration(
                  labelText: 'Angiv fødevare',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Gram',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.blueGrey,
                  padding: EdgeInsets.zero,
                ),
                onPressed: addFoodToMeal,
                child: const Icon(Icons.check, size: 26),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.white,
                ),
                onPressed: deleteWholeMeal,
                child: const Text('Slet måltid'),
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
    );
  }

  @override
  void dispose() {
    foodController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.mealName),
        backgroundColor: AppColors.brown,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Expanded(child: mealList()),
              inputFields(),
            ],
          ),
        ),
      ),
    );
  }
}
