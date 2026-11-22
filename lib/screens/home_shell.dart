import 'dart:io';

import 'package:favorite_places/l10n/l10n.dart';
import 'package:favorite_places/screens/account.dart';
import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/screens/add_place.dart';
import 'package:favorite_places/screens/feed.dart';
import 'package:favorite_places/screens/discover.dart';
import 'package:favorite_places/screens/places_map.dart';
import 'package:favorite_places/widgets/glass_tab_bar.dart';
import 'package:favorite_places/widgets/image_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// The app's root: Discover / Map / Feed / Account under the floating glass bar,
/// with the camera in its middle.
///
/// Each tab has its own navigator, so a place's details open *inside* the
/// tab with the bar still showing, as in the design. Tapping the current tab
/// again goes back to its first screen.
///
/// The camera opens straight away; once a photo is taken the add form opens
/// with that photo already filled in.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<GlassTab> get _tabs => [
    GlassTab(label: context.l10n.tabDiscover, icon: 'tab_heart'),
    GlassTab(label: context.l10n.tabMap, icon: 'tab_map'),
    GlassTab(label: context.l10n.tabFeed, icon: 'tab_people'),
    GlassTab(label: context.l10n.tabAccount, icon: 'tab_person'),
  ];

  /// Pages 0-3 are the tabs; page 4 is the add form.
  static const int _addPage = 4;
  static const int _accountPage = 3;

  final ImagePicker _picker = ImagePicker();
  final List<GlobalKey<NavigatorState>> _navigators = [
    for (var i = 0; i < _addPage; i++) GlobalKey<NavigatorState>(),
  ];

  int _page = 0;
  int _pageBeforeAdd = 0;
  final Set<int> _opened = {0};
  bool _capturing = false;

  /// Photo from the camera button, handed to the add form.
  File? _capturedImage;

  /// Replaced each time the form opens fresh, so it starts empty.
  Key _addFormKey = UniqueKey();

  void _openTab(int page) {
    if (page == _page) {
      // Second tap on the current tab: back to its first screen.
      _navigators[page].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _page = page;
      _opened.add(page);
    });
  }

  /// Opens the add form, optionally with a photo already in it.
  void _openAddForm({File? image}) {
    setState(() {
      if (_page != _addPage) {
        _pageBeforeAdd = _page;
      }
      _capturedImage = image;
      _addFormKey = UniqueKey();
      _page = _addPage;
      _opened.add(_addPage);
    });
  }

  void _closeAddForm() {
    setState(() {
      _page = _pageBeforeAdd;
      _capturedImage = null;
      _addFormKey = UniqueKey();
    });
  }

  Future<void> _takePhoto() async {
    final l10n = context.l10n;
    if (_capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      XFile? photo;
      try {
        photo = await _pick(ImageSource.camera);
      } on PlatformException catch (error) {
        if (error.code != 'no_available_camera') {
          _showMessage(photoErrorMessage(l10n, error));
          return;
        }
        // Simulators have no camera: fall back to the photo library.
        _showMessage(l10n.noCameraChoosePhoto);
        photo = await _pick(ImageSource.gallery);
      }
      if (!mounted || photo == null) {
        return;
      }
      _openAddForm(image: File(photo.path));
    } on PlatformException catch (error) {
      _showMessage(photoErrorMessage(l10n, error));
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<XFile?> _pick(ImageSource source) {
    return _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
  }

  /// Goes to Account, where the new place shows in the user's grid.
  void _onPlaceSaved() {
    setState(() {
      _page = _accountPage;
      _opened.add(_accountPage);
      _capturedImage = null;
      _addFormKey = UniqueKey();
    });
    _showMessage(context.l10n.savedToMyPlaces);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _rootOf(int page) {
    switch (page) {
      case 0:
        return const DiscoverScreen();
      case 1:
        return const PlacesMapScreen();
      case 2:
        return const FeedScreen();
      default:
        return const AccountScreen();
    }
  }

  Widget _buildPage(int page) {
    if (page == _addPage) {
      return AddedPlaceScreen(
        key: _addFormKey,
        initialImage: _capturedImage,
        onSaved: _onPlaceSaved,
        onCancel: _closeAddForm,
      );
    }
    return Navigator(
      key: _navigators[page],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => _rootOf(page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Android back button: close the form or pop inside the current tab
    // first; leave the app only from a tab's first screen.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_page == _addPage) {
          _closeAddForm();
          return;
        }
        final tab = _navigators[_page].currentState;
        if (tab != null && tab.canPop()) {
          tab.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // Content scrolls underneath the glass bar.
        extendBody: true,
        body: IndexedStack(
          index: _page,
          children: [
            for (var i = 0; i <= _addPage; i++)
              _opened.contains(i) ? _buildPage(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: GlassTabBar(
          tabs: _tabs,
          currentIndex: _page == _addPage ? -1 : _page,
          onSelect: _openTab,
          onCamera: _takePhoto,
          cameraBusy: _capturing,
          // Dark glass in dark mode, when the map tiles are dark too.
          dark: AppColors.isDark,
        ),
      ),
    );
  }
}
