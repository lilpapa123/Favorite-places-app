import 'dart:io';

import 'package:favorite_places/providers/user_palces.dart'
    show userPlacesProvider;
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/ascii_button.dart';
import 'package:favorite_places/widgets/ascii_label.dart';
import 'package:favorite_places/widgets/ascii_text_field.dart';
import 'package:favorite_places/widgets/blinking_cursor.dart';
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
  final TextEditingController _titleController = TextEditingController();
  File? _selectedImage;

  void _savePlace() {
    final String enteredTitle = _titleController.text.trim();
    if (enteredTitle.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('title required')));
      return;
    }

    FocusScope.of(context).unfocus();
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('>', style: AsciiType.heading(color: AsciiPalette.accent)),
            const SizedBox(width: AsciiSpace.sm),
            Flexible(
              child: Text(
                'new place',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AsciiType.heading(),
              ),
            ),
            const SizedBox(width: AsciiSpace.sm),
            const BlinkingCursor(height: 18),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AsciiShape.borderWidth),
          child: Divider(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AsciiSpace.lg,
          AsciiSpace.xl,
          AsciiSpace.lg,
          AsciiSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AsciiLabel('title'),
            const SizedBox(height: AsciiSpace.sm),
            AsciiTextField(
              controller: _titleController,
              hintText: 'the cafe on the corner',
              autofocus: true,
            ),
            const SizedBox(height: AsciiSpace.xl),
            ImageInput(
              onImagePicked: (image) => setState(() => _selectedImage = image),
            ),
            const SizedBox(height: AsciiSpace.lg),
            Text(
              'entries are kept on this device only.',
              style: AsciiType.small(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AsciiPalette.canvas,
            border: Border(
              top: BorderSide(
                color: AsciiPalette.line,
                width: AsciiShape.borderWidth,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AsciiSpace.lg,
            AsciiSpace.md,
            AsciiSpace.lg,
            AsciiSpace.md,
          ),
          child: AsciiButton(
            label: 'save place',
            icon: Icons.check,
            expanded: true,
            onPressed: _savePlace,
          ),
        ),
      ),
    );
  }
}
