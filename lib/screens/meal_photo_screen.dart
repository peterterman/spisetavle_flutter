import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_service.dart';
import '../services/openai_service.dart';
import 'input_screen.dart';

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

    for (final food in _foods) {
      try {
        await DatabaseService.instance.insertCalculatedLogEntry(
          date: widget.date,
          foodName: food['name'].toString(),
          amount: (food['grams'] as num).toDouble(),
          user: widget.user,
          tid: _tid,
        );
      } catch (_) {
        // Ignorer fødevarer som ikke findes i Frida
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
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
