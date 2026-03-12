import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _bloodGroupController;
  
  List<Map<String, TextEditingController>> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['full_name']);
    _phoneController = TextEditingController(text: widget.userData['phone_number']);
    _ageController = TextEditingController(text: widget.userData['age']);
    _bloodGroupController = TextEditingController(text: widget.userData['blood_group']);

    // Load existing contacts
    List<dynamic> existingContacts = widget.userData['emergency_contacts'] ?? [];
    for (var c in existingContacts) {
      _contacts.add({
        'name': TextEditingController(text: c['name']),
        'number': TextEditingController(text: c['number']),
      });
    }
  }

  void _addContact() {
    setState(() {
      _contacts.add({'name': TextEditingController(), 'number': TextEditingController()});
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, String>> contactsJson = _contacts.map((c) => {
        'name': c['name']!.text.trim(),
        'number': c['number']!.text.trim(),
      }).toList();

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'age': _ageController.text.trim(),
        'blood_group': _bloodGroupController.text.trim(),
        'emergency_contacts': contactsJson,
      }).eq('id', widget.userData['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Emergency contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_box, color: Colors.pinkAccent, size: 32), onPressed: _addContact)
              ],
            ),
            const SizedBox(height: 16),
            
            ...List.generate(_contacts.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                    const SizedBox(height: 8),
                    TextField(controller: _contacts[index]['name'], decoration: const InputDecoration(hintText: 'Name', isDense: true)),
                    const SizedBox(height: 8),
                    TextField(controller: _contacts[index]['number'], decoration: const InputDecoration(hintText: 'Number', isDense: true)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}