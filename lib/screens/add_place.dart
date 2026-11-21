import 'dart:io';

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/user_palces.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_icon.dart';
import 'package:favorite_places/widgets/app_text_field.dart';
import 'package:favorite_places/widgets/category_chips.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:favorite_places/widgets/location_input.dart';
import 'package:favorite_places/widgets/page_header.dart';
import 'package:favorite_places/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Add place" form — also used to edit a saved place ([existing]).
///
/// In the shell it lives on its own page: [onSaved] / [onCancel] let the
/// shell switch back. Without them (pushed as a route) it pops instead.
class AddedPlaceScreen extends ConsumerStatefulWidget {
  const AddedPlaceScreen({
    super.key,
    this.onSaved,
    this.onCancel,
    this.initialImage,
    this.existing,
  });

  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  /// Photo taken with the tab bar's camera, pre-filled in the form.
  final File? initialImage;

  /// The place being edited, if any.
  final Place? existing;

  @override
  ConsumerState<AddedPlaceScreen> createState() => _AddedPlaceScreenState();
}

class _AddedPlaceScreenState extends ConsumerState<AddedPlaceScreen> {
  static const int _noteLimit = 200;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  PlaceCategory _category = PlaceCategory.cafe;
  File? _selectedImage;
  PlaceLocation? _selectedLocation;

  bool get _editing => widget.existing != null;
  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _noteController.text = existing.note;
      _category = existing.category;
      _selectedImage = existing.image;
      _selectedLocation = existing.location;
    } else {
      _selectedImage = widget.initialImage;
    }
    // Rebuild so "Save place" enables as soon as there's a name.
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  void _savePlace() {
    if (!_canSave) {
      return;
    }
    FocusScope.of(context).unfocus();
    final notifier = ref.read(userPlacesProvider.notifier);
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final existing = widget.existing;

    if (existing != null) {
      notifier.updatePlace(
        existing.copyWith(
          title: title,
          category: _category,
          note: note,
          image: _selectedImage,
          location: _selectedLocation,
          clearLocation: _selectedLocation == null,
        ),
      );
    } else {
      notifier.addPlace(
        title,
        category: _category,
        note: note,
        image: _selectedImage,
        location: _selectedLocation,
      );
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? context.l10n.changesSaved : context.l10n.savedToMyPlaces),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  void _close() {
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: _editing ? context.l10n.editPlace : context.l10n.addPlace,
                  subtitle: _editing
                      ? context.l10n.editPlaceSubtitle
                      : context.l10n.addPlaceSubtitle,
                  trailing: CircleIconButton(
                    icon: const AppIcon('close'),
                    semanticLabel: context.l10n.close,
                    onPressed: _close,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.page,
                  2,
                  AppSpace.page,
                  bottomBarClearance(context),
                ),
                sliver: SliverList.list(
                  children: [
                    ImageInput(
                      initialImage: _selectedImage,
                      onImagePicked: (image) =>
                          setState(() => _selectedImage = image),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppTextField(
                      label: context.l10n.placeName,
                      controller: _titleController,
                      hintText: context.l10n.placeNameHint,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    CategoryChips(
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppTextField(
                      label: context.l10n.littleNote,
                      trailingLabel: context.l10n.optional,
                      controller: _noteController,
                      hintText: context.l10n.littleNoteHint,
                      maxLines: 2,
                      maxLength: _noteLimit,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    LocationInput(
                      initial: _selectedLocation,
                      onLocationPicked: (location) =>
                          setState(() => _selectedLocation = location),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.onlyYouCanSee,
                      style: AppText.meta().copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    PillButton(
                      label: _editing ? context.l10n.saveChanges : context.l10n.savePlace,
                      leading: const AppIcon('heart_white'),
                      large: true,
                      expanded: true,
                      onPressed: _canSave ? _savePlace : null,
                    ),
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
