import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan fødevare')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;

          final code = capture.barcodes.first.rawValue;

          if (code == null || code.isEmpty) return;

          _done = true;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
