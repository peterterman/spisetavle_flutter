import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../theme/app_colors.dart';

class AiMatchScreen extends StatefulWidget {
  final String aiFood;

  const AiMatchScreen({super.key, required this.aiFood});

  @override
  State<AiMatchScreen> createState() => _AiMatchScreenState();
}

class _AiMatchScreenState extends State<AiMatchScreen> {
  List<String> matches = [];

  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();

    searchController = TextEditingController(text: widget.aiFood);

    loadMatches();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMatches() async {
    // Prøv eksisterende alias først
    final alias = await DatabaseService.instance.findBestAiAlias(widget.aiFood);

    if (alias != null) {
      if (!mounted) return;

      Navigator.pop(context, alias);
      return;
    }

    // Ellers søg normalt
    final result = await DatabaseService.instance.findAiMatches(widget.aiFood);

    if (!mounted) return;

    setState(() {
      matches = result;
    });
  }

  Future<void> searchNow() async {
    final result = await DatabaseService.instance.findAiMatches(
      searchController.text,
    );

    if (!mounted) return;

    setState(() {
      matches = result;
    });
  }

  Future<void> selectMatch(String fridaName) async {
    await DatabaseService.instance.saveAiAlias(widget.aiFood, fridaName);

    if (!mounted) return;

    Navigator.pop(context, fridaName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI match'),
        backgroundColor: AppColors.brown,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'AI fandt: ${widget.aiFood}',
            style: const TextStyle(fontSize: 22),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Søg i Frida',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => searchNow(),
          ),

          const SizedBox(height: 8),

          ElevatedButton(onPressed: searchNow, child: const Text('Søg')),

          const SizedBox(height: 16),

          if (matches.isEmpty)
            const Text('Ingen forslag', style: TextStyle(fontSize: 18))
          else
            ...matches.map(
              (name) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: ListTile(
                  title: Text(name),
                  onTap: () => selectMatch(name),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
