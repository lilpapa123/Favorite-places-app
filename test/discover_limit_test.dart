import 'package:favorite_places/providers/social_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Discover asks for the next page only once the last one is full', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final limit = container.read(discoverLimitProvider.notifier);
    const page = DiscoverLimit.page;

    limit.more(page - 1);
    expect(container.read(discoverLimitProvider), page);

    limit.more(page);
    expect(container.read(discoverLimitProvider), page * 2);

    // Scrolling again before the page arrives doesn't skip ahead.
    limit.more(page);
    expect(container.read(discoverLimitProvider), page * 2);
  });
}
