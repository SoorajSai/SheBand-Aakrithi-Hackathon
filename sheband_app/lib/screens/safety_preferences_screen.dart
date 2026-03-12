import 'package:flutter/material.dart';

class SafetyPreferencesScreen extends StatefulWidget {
  const SafetyPreferencesScreen({super.key});

  @override
  State<SafetyPreferencesScreen> createState() => _SafetyPreferencesScreenState();
}

class _SafetyPreferencesScreenState extends State<SafetyPreferencesScreen> {
  bool _voiceSos = true;
  bool _gestureDetection = true;
  bool _autoCall112 = false;
  List<String> _keywords = ['112', 'SOS', 'Save me'];
  final _keywordController = TextEditingController();

  void _addKeyword() {
    if (_keywordController.text.isNotEmpty) {
      setState(() {
        _keywords.add(_keywordController.text);
        _keywordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          SwitchListTile(
            title: const Text('Voice SOS Detection'),
            subtitle: const Text('Trigger SOS using voice keywords'),
            value: _voiceSos,
            onChanged: (val) => setState(() => _voiceSos = val),
            activeColor: Colors.pinkAccent,
          ),
          SwitchListTile(
            title: const Text('Gesture Detection'),
            subtitle: const Text('Trigger SOS by shaking device'),
            value: _gestureDetection,
            onChanged: (val) => setState(() => _gestureDetection = val),
            activeColor: Colors.pinkAccent,
          ),
          SwitchListTile(
            title: const Text('Auto Call 112'),
            subtitle: const Text('Automatically call emergency services'),
            value: _autoCall112,
            onChanged: (val) => setState(() => _autoCall112 = val),
            activeColor: Colors.pinkAccent,
          ),
          const Divider(height: 48),
          const Text('Custom SOS Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    hintText: 'Add keyword...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.pinkAccent, size: 40),
                onPressed: _addKeyword,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _keywords.map((k) => Chip(
              label: Text(k),
              onDeleted: () {
                setState(() {
                  _keywords.remove(k);
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}