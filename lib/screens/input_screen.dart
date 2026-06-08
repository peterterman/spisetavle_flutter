import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class InputScreen extends StatefulWidget {
  final String user;
  final String date;
  final String userName;

  const InputScreen({
    super.key,
    required this.user,
    required this.date,
    required this.userName,
  });

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final foodController = TextEditingController();
  final amountController = TextEditingController();

  String inputType = 'food';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    foodController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String get currentTid {
    switch (_tabController.index) {
      case 0:
        return 'm';
      case 1:
        return 'f';
      case 2:
        return 'a';
      case 3:
        return 's';
      default:
        return 'm';
    }
  }

  double readAmount() {
    return double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
  }

  Future<List<String>> searchMeals(String pattern) async {
    return DatabaseService.instance.searchMeals(pattern);
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
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  Future<void> saveCurrentInput() async {
    final typedName = foodController.text.trim();
    final amount = readAmount();

    if (typedName.isEmpty) return;
    if (inputType == 'food' && amount <= 0) return;

    if (inputType == 'meal') {
      await DatabaseService.instance.insertMealIntoLog(
        mealName: typedName,
        date: widget.date,
        user: widget.user,
        tid: currentTid,
      );
    } else {
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

      await DatabaseService.instance.insertFoodItemLogEntry(
        date: widget.date,
        food: food,
        displayName: forceFrida ? food.navn : alias,
        amount: amount,
        user: widget.user,
        tid: currentTid,
      );
    }

    foodController.clear();
    amountController.clear();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> showFunctions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Samme som i går'),
              onTap: () => Navigator.pop(context, 'yesterday'),
            ),
            ListTile(
              title: const Text('Kopiér fra anden bruger'),
              onTap: () => Navigator.pop(context, 'other_user'),
            ),
            ListTile(
              title: const Text('Opret måltid af aktuelle poster'),
              onTap: () => Navigator.pop(context, 'create_meal'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'yesterday') {
      await DatabaseService.instance.copyFromYesterday(
        user: widget.user,
        targetDate: widget.date,
        tid: currentTid,
      );
      setState(() {});
    }

    if (choice == 'other_user') {
      final fromUser = widget.user == 'bruger1' ? 'bruger2' : 'bruger1';

      await DatabaseService.instance.copyFromOtherUser(
        fromUser: fromUser,
        toUser: widget.user,
        date: widget.date,
        tid: currentTid,
      );
      setState(() {});
    }

    if (choice == 'create_meal') {
      await createMealFromCurrentEntries();
    }
  }

  Future<void> createMealFromCurrentEntries() async {
    final controller = TextEditingController();

    final mealName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opret måltid'),
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

    await DatabaseService.instance.createMealFromLogEntries(
      mealName: mealName,
      user: widget.user,
      date: widget.date,
      tid: currentTid,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Måltid "$mealName" oprettet')));

    setState(() {});
  }

  Future<void> removeAndEdit(Map<String, Object?> row) async {
    final id = int.tryParse(row['_id']?.toString() ?? '');

    if (id != null) {
      await DatabaseService.instance.deleteLogEntry(id);
    }

    foodController.text = row['name']?.toString() ?? '';
    amountController.text = amountText(row['amount']);

    if (!mounted) return;
    setState(() {});
  }

  String amountText(Object? value) {
    final n =
        double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  Widget inputList(String tid) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: DatabaseService.instance.getLogForMealTime(
        user: widget.user,
        date: widget.date,
        tid: tid,
      ),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => removeAndEdit(row),
                      child: const Icon(Icons.close, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      row['name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppSizes.normal),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      amountText(row['amount']),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: AppSizes.normal),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget foodTextField() {
    return Autocomplete<String>(
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      optionsBuilder: (value) async {
        if (value.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }

        return await DatabaseService.instance.searchFoods(value.text);
      },
      onSelected: (value) {
        foodController.text = value;
        amountController.text = '100';
        setState(() {});
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.text = foodController.text;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        controller.addListener(() {
          if (foodController.text != controller.text) {
            foodController.text = controller.text;
          }
        });

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Angiv fødevare',
            isDense: true,
          ),
        );
      },
    );
  }

  Widget mealAutocompleteField() {
    return Autocomplete<String>(
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      optionsBuilder: (value) async {
        if (value.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }

        return await searchMeals(value.text);
      },
      onSelected: (value) {
        foodController.text = value;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.text = foodController.text;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        controller.addListener(() {
          if (foodController.text != controller.text) {
            foodController.text = controller.text;
          }
        });

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Angiv måltid',
            isDense: true,
          ),
        );
      },
    );
  }

  Widget inputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: showFunctions,
            child: const Text(
              'Vis funktioner...',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: inputType == 'food'
                  ? foodTextField()
                  : mealAutocompleteField(),
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
              width: 64,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.blueGrey,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: saveCurrentInput,
                child: const Icon(Icons.check, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Radio<String>(
              value: 'food',
              groupValue: inputType,
              onChanged: (value) {
                if (value == null) return;
                setState(() => inputType = value);
              },
            ),
            const Text('Fødevare'),
            Radio<String>(
              value: 'meal',
              groupValue: inputType,
              onChanged: (value) {
                if (value == null) return;
                setState(() => inputType = value);
              },
            ),
            const Text('Måltid'),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ],
    );
  }

  Widget tabPage(String tid) {
    return Column(
      children: [
        Expanded(child: inputList(tid)),
        inputFields(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.date} - ${widget.userName}',
                  style: TextStyle(fontSize: AppSizes.heading),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.brown,
                unselectedLabelColor: Colors.black54,
                indicatorColor: AppColors.brown,
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'Morgen'),
                  Tab(text: 'Frokost'),
                  Tab(text: 'Aften'),
                  Tab(text: 'Snack'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    tabPage('m'),
                    tabPage('f'),
                    tabPage('a'),
                    tabPage('s'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
