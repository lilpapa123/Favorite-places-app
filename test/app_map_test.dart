import 'package:favorite_places/theme/app_theme.dart';
import 'package:favorite_places/widgets/app_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.isDark = false);

  test('map tiles are tinted in dark mode only', () {
    AppColors.isDark = false;
    expect(AppMap.tiles(), isA<TileLayer>());
    AppColors.isDark = true;
    expect(AppMap.tiles(), isA<ColorFiltered>());
  });
}
