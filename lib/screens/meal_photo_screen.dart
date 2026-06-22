import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_item.dart';
import '../database/database_service.dart';
import '../services/openai_service.dart';
import 'input_screen.dart';
import 'ai_match_screen.dart';

class MealPhotoScreen extends StatefulWidget {
  final String user;
  final String date;
  final String userName;

  const MealPhotoScreen({
    super.key,
    required this.user,
    required this.date,
    required this.userName,
  });

  @override
  State<MealPhotoScreen> createState() => _MealPhotoScreenState();
}

class _MealPhotoScreenState extends State<MealPhotoScreen> {
  File? _image;
  bool _isAnalyzing = false;
  String _tid = 'f';

  final List<Map<String, dynamic>> _foods = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  Future<FoodItem?> _chooseFridaFood(String aiName) async {
    final controller = TextEditingController(text: aiName);
    List<FoodItem> matches = await DatabaseService.instance
        .searchFridaFoodItems(aiName);

    if (!mounted) return null;

    return showDialog<FoodItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchNow() async {
              final query = controller.text.trim();
              if (query.isEmpty) return;

              final localFood = await DatabaseService.instance
                  .getLocalFoodExact(query);

              List<FoodItem> found = [];

              if (localFood != null) {
                found = [localFood];
              } else {
                found = await DatabaseService.instance.searchFridaFoodItems(
                  query,
                );
              }

              if (!context.mounted) return;

              setDialogState(() {
                matches = found;
              });
            }

            return AlertDialog(
              title: Text('Vælg Frida-post for "$aiName"'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Søg i Frida',
                        hintText: 'fx æg, tomat, persille',
                      ),
                      onSubmitted: (_) => searchNow(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: searchNow,
                        child: const Text('Søg'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: matches.isEmpty
                          ? const Center(child: Text('Ingen match endnu'))
                          : ListView.separated(
                              itemCount: matches.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Spring over'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _foods.clear();
      });

      await _analyzeWithAI();
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final foods = await OpenAiService.analyzeMealPhoto(_image!);

      if (!mounted) return;

      setState(() {
        _foods.clear();
        _foods.addAll(foods);
      });
    } catch (e) {
      debugPrint('AI FEJL: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI-fejl - se terminal'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _saveFoods() async {
    if (_foods.isEmpty) return;

    for (final item in _foods) {
      final aiName = item['name'].toString().trim();
      final amount = (item['grams'] as num).toDouble();

      if (aiName.isEmpty || amount <= 0) continue;

      // 1. Prøv AI-alias først
      final alias = await DatabaseService.instance.findBestAiAlias(aiName);

      FoodItem? food;

      // 2. Alias fundet
      if (alias != null) {
        food = await DatabaseService.instance.getFoodValues(alias);
      }

      // 3. Fallback til eksisterende logik
      food ??= await DatabaseService.instance.getLocalFoodExact(aiName);
      food ??= await DatabaseService.instance.getFoodValues(aiName);
      if (food == null) {
        final fridaName = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => AiMatchScreen(aiFood: aiName)),
        );

        if (fridaName != null) {
          food = await DatabaseService.instance.getFoodValues(fridaName);
        }
        if (!mounted) return;

        if (food == null) {
          continue;
        }

        await DatabaseService.instance.saveFoodToLocalAlias(
          alias: aiName,
          food: food,
        );

        await DatabaseService.instance.saveAiAlias(aiName, food.navn);
      }

      await DatabaseService.instance.insertFoodItemLogEntry(
        date: widget.date,
        food: food,
        displayName: aiName,
        amount: amount,
        user: widget.user,
        tid: _tid,
      );
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(
          user: widget.user,
          date: widget.date,
          userName: widget.userName,
          initialTid: _tid,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyser måltid')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _image == null
                    ? const Text(
                        'Tag et billede af dit måltid',
                        style: TextStyle(fontSize: 18),
                      )
                    : Image.file(_image!),
              ),
            ),

            const SizedBox(height: 12),

            if (_foods.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _foods.length,
                  itemBuilder: (context, index) {
                    final food = _foods[index];

                    return ListTile(
                      title: Text(food['name'].toString()),
                      trailing: Text('${food['grams']} g'),
                    );
                  },
                ),
              ),

            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Analyserer billede...'),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            DropdownButton<String>(
              value: _tid,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'm', child: Text('Morgen')),
                DropdownMenuItem(value: 'f', child: Text('Frokost')),
                DropdownMenuItem(value: 'a', child: Text('Aften')),
                DropdownMenuItem(value: 's', child: Text('Snack')),
              ],
              onChanged: _isAnalyzing
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _tid = value;
                      });
                    },
            ),

            const SizedBox(height: 8),

            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _foods.isEmpty || _isAnalyzing ? null : _saveFoods,
                  child: const Text('Gem'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
