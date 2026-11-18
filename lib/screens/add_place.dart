import 'dart:io';

import 'package:favorite_places/providers/user_palces.dart'
    show userPlacesProvider;
import 'package:favorite_places/widgets/image_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddedPlaceScreen extends ConsumerStatefulWidget {
  const AddedPlaceScreen({super.key});

  @override
  ConsumerState<AddedPlaceScreen> createState() {
    return _AddedPlaceScreenState();
  }
}

class _AddedPlaceScreenState extends ConsumerState<AddedPlaceScreen> {
  final _titleController = TextEditingController();
  File? _selectedImage;

  void _savePlace() {
    final enteredTitle = _titleController.text.trim();
    if (enteredTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title first.')),
      );
      return;
    }

    ref
        .read(userPlacesProvider.notifier)
        .addPlace(enteredTitle, image: _selectedImage);

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a New Place')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              controller: _titleController,
            ),
            const SizedBox(height: 20),
            ImageInput(
              onImagePicked: (image) => setState(() => _selectedImage = image),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _savePlace,
              icon: const Icon(Icons.add),
              label: const Text('Add Place'),
            ),
          ],
        ),
      ),
    );
  }
}
