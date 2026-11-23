import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/providers/social_provider.dart';
import 'package:flutter/foundation.dart';

/// Made-up people and their shared places, so Discover isn't empty while
/// developing. Debug and profile builds only; never in release or tests.
final bool showSamplePosts =
    !kReleaseMode && !Platform.environment.containsKey('FLUTTER_TEST');

/// Sample uids start with this, so they are never written to Firestore.
const samplePrefix = 'sample-';

bool isSampleUid(String uid) => uid.startsWith(samplePrefix);

final List<UserProfile> sampleProfiles = [
  for (final (id, username, name, bio) in const [
    ('lina', 'lina.travels', 'Lina Haddad', 'Coffee first, then the view.'),
    ('mert', 'mert_outdoors', 'Mert Yılmaz', 'Weekend hikes and long walks.'),
    ('sofia', 'sofia.eats', 'Sofia Costa', 'Small cafés in big cities.'),
    ('omar', 'omar.k', 'Omar Khalil', 'Desert nights and city lights.'),
    ('yuki', 'yuki_walks', 'Yuki Tanaka', 'Quiet corners, one photo at a time.'),
    ('emma', 'emma.coast', 'Emma Clarke', 'Beaches, cliffs and sea air.'),
    ('diego', 'diego.trails', 'Diego Ramírez', 'Mountains above everything.'),
    ('aisha', 'aisha.views', '', 'Rooftops and sunsets.'),
    ('noah', 'noah_camps', 'Noah Becker', 'Tent, stars, repeat.'),
    ('zeynep', 'zeynep.ist', 'Zeynep Aydın', 'Istanbul, street by street.'),
    ('maya', 'maya.everywhere', 'Maya Lin', 'Every kind of place, everywhere.'),
  ])
    UserProfile(
      uid: '$samplePrefix$id',
      username: username,
      displayName: name,
      bio: bio,
    ),
];

UserProfile? sampleProfile(String uid) =>
    sampleProfiles.where((p) => p.uid == uid).firstOrNull;

/// (followers, following) shown on a sample person's profile. Maya, who
/// has every badge, also shows a big following.
(int, int) sampleFollowCounts(String uid) =>
    uid == '${samplePrefix}maya' ? (945, 180) : (0, 0);

/// 57 shared places, newest first, as (owner uid, place).
List<(String, Place)> samplePosts() {
  final now = DateTime.now();
  var n = 0;
  (String, Place) post(
    String owner,
    String title,
    PlaceCategory category,
    String note,
    int photos,
    double lat,
    double lng,
    String area,
    String city,
    String country,
  ) {
    final id = 'sample-post-${n++}';
    return (
      '$samplePrefix$owner',
      Place(
        id: id,
        title: title,
        category: category,
        note: note,
        // shortcut: random stock photos, not of the real place; fine for
        // filling the screen while developing.
        photos: [
          for (var i = 0; i < photos; i++)
            'https://picsum.photos/seed/$id-$i/1200/900',
        ],
        createdAt: now.subtract(Duration(hours: 5 + n * 9)),
        location: PlaceLocation(
          latitude: lat,
          longitude: lng,
          area: area,
          city: city,
          country: country,
        ),
      ),
    );
  }

  const cafe = PlaceCategory.cafe;
  const view = PlaceCategory.viewpoint;
  const walk = PlaceCategory.walk;
  const hike = PlaceCategory.hike;
  const nature = PlaceCategory.nature;
  const beach = PlaceCategory.beach;
  const camp = PlaceCategory.camping;
  const night = PlaceCategory.night;

  return [
    post('zeynep', 'Karaköy morning coffee', cafe, 'Simit, Turkish coffee and the ferries going by.', 3, 41.0227, 28.9770, 'Karaköy', 'Istanbul', 'Türkiye'),
    post('lina', 'Rainbow Street sunset', view, 'Walk down at golden hour, stay for the lights.', 2, 31.9510, 35.9239, 'Jabal Amman', 'Amman', 'Jordan'),
    post('mert', 'Lycian Way, Faralya stretch', hike, 'Cliff path over Butterfly Valley. Bring water.', 4, 36.4994, 29.1323, 'Faralya', 'Fethiye', 'Türkiye'),
    post('sofia', 'Tiny bakery in Alfama', cafe, 'Pastel de nata still warm at 8 am.', 2, 38.7114, -9.1300, 'Alfama', 'Lisbon', 'Portugal'),
    post('omar', 'Dubai Marina at night', night, 'The walk along the water never gets old.', 3, 25.0805, 55.1403, 'Dubai Marina', 'Dubai', 'UAE'),
    post('yuki', 'Philosopher’s Path', walk, 'Best in early April when the cherries bloom.', 4, 35.0270, 135.7944, 'Sakyo', 'Kyoto', 'Japan'),
    post('emma', 'Bondi to Coogee walk', beach, 'Six kilometres of cliffs, pools and beaches.', 3, -33.8915, 151.2767, 'Bondi', 'Sydney', 'Australia'),
    post('diego', 'Laguna 69', hike, 'Hard climb, unreal blue water at the top.', 4, -9.0117, -77.6082, 'Huascarán', 'Huaraz', 'Peru'),
    post('aisha', 'Rooftop over the old city', view, 'Mint tea and the call to prayer at dusk.', 2, 31.6258, -7.9891, 'Medina', 'Marrakesh', 'Morocco'),
    post('noah', 'Lake camp in the Dolomites', camp, 'Woke up to the peaks reflected in the water.', 3, 46.6993, 12.1847, 'Braies', 'South Tyrol', 'Italy'),
    post('zeynep', 'Balat colorful streets', walk, 'Get lost between the painted houses.', 3, 41.0296, 28.9487, 'Balat', 'Istanbul', 'Türkiye'),
    post('lina', 'Wadi Rum overnight', camp, 'No light for miles. So many stars.', 4, 29.5759, 35.4196, 'Wadi Rum', 'Aqaba', 'Jordan'),
    post('sofia', 'Café de Flore corner table', cafe, 'Pricey, but the people-watching is free.', 1, 48.8540, 2.3326, 'Saint-Germain', 'Paris', 'France'),
    post('mert', 'Cappadocia sunrise', view, 'Hundreds of balloons over the valleys.', 4, 38.6431, 34.8289, 'Göreme', 'Nevşehir', 'Türkiye'),
    post('omar', 'Al Seef old souq', walk, 'Lanterns, spices and abra boats.', 2, 25.2637, 55.2972, 'Al Seef', 'Dubai', 'UAE'),
    post('yuki', 'Arashiyama bamboo grove', nature, 'Go before 7 am to have it to yourself.', 3, 35.0170, 135.6713, 'Arashiyama', 'Kyoto', 'Japan'),
    post('emma', 'Porthcurno beach', beach, 'Turquoise water you won’t believe is in England.', 2, 50.0425, -5.6545, 'Porthcurno', 'Cornwall', 'UK'),
    post('diego', 'Torres del Paine base', hike, 'Windy, cold and worth every step.', 4, -50.9423, -72.9686, 'Torres del Paine', 'Magallanes', 'Chile'),
    post('aisha', 'Galata Tower at blue hour', view, 'The whole city turns gold, then blue.', 2, 41.0256, 28.9741, 'Galata', 'Istanbul', 'Türkiye'),
    post('noah', 'Black Forest trail camp', camp, 'Pine smell, quiet nights, a little stream.', 2, 47.9990, 8.0780, 'Feldberg', 'Black Forest', 'Germany'),
    post('zeynep', 'Moda seaside walk', walk, 'Ice cream in hand, sunset over the sea.', 2, 40.9845, 29.0247, 'Moda', 'Istanbul', 'Türkiye'),
    post('lina', 'Petra by night', night, 'Candles in front of the Treasury.', 3, 30.3285, 35.4444, 'Wadi Musa', 'Petra', 'Jordan'),
    post('sofia', 'Flat white in Shoreditch', cafe, 'Good beans, better pastries.', 1, 51.5246, -0.0780, 'Shoreditch', 'London', 'UK'),
    post('mert', 'Uludağ forest walk', nature, 'Cool air even in August.', 2, 40.0715, 29.2210, 'Uludağ', 'Bursa', 'Türkiye'),
    post('omar', 'Desert dunes at sunset', view, 'Sit on the ridge and watch the colors change.', 3, 24.8607, 55.6264, 'Al Lahbab', 'Dubai', 'UAE'),
    post('yuki', 'Shibuya crossing from above', night, 'Watch the scramble from the café upstairs.', 2, 35.6595, 139.7005, 'Shibuya', 'Tokyo', 'Japan'),
    post('emma', 'Camps Bay sundowner', beach, 'Table Mountain behind, Atlantic in front.', 3, -33.9505, 18.3776, 'Camps Bay', 'Cape Town', 'South Africa'),
    post('diego', 'Central Park loop', walk, 'Six miles, all the seasons in one city.', 2, 40.7712, -73.9742, 'Upper West Side', 'New York', 'USA'),
    post('aisha', 'Bosphorus from Çamlıca', view, 'Both continents in one look.', 1, 41.0274, 29.0688, 'Çamlıca', 'Istanbul', 'Türkiye'),
    post('noah', 'Swiss alpine meadow', nature, 'Cowbells and wildflowers above Grindelwald.', 4, 46.6244, 8.0414, 'Grindelwald', 'Bern', 'Switzerland'),
    // Two more for Noah: five cities, countries on three continents, so
    // his profile shows six badges.
    post('noah', 'Lake Louise lakeside camp', camp, 'Turquoise water, glaciers, and elk at dawn.', 3, 51.4254, -116.1773, 'Lake Louise', 'Banff', 'Canada'),
    post('noah', 'Milford Sound lookout', nature, 'Waterfalls straight into the fjord after rain.', 2, -44.6414, 167.8974, 'Milford Sound', 'Fiordland', 'New Zealand'),
    // Maya: 25 places of every type on every continent, so she earns all
    // 12 badges.
    post('maya', 'Mount Fuji summit trail', hike, 'Start at night, watch the sunrise from the top.', 1, 35.3606, 138.7274, 'Fujinomiya', 'Shizuoka', 'Japan'),
    post('maya', 'Kilimanjaro Machame route', hike, 'Seven days, worth every step.', 1, -3.0674, 37.3556, 'Machame', 'Moshi', 'Tanzania'),
    post('maya', 'Matterhorn Hörnli trail', hike, 'The peak looks close all day.', 1, 45.9763, 7.6586, 'Hörnli', 'Zermatt', 'Switzerland'),
    post('maya', 'Plitvice Lakes boardwalk', nature, 'Sixteen lakes, all a different blue.', 1, 44.8654, 15.5820, 'Plitvice', 'Lika', 'Croatia'),
    post('maya', 'Iguazu Falls, Devil\'s Throat', nature, 'You hear it long before you see it.', 1, -25.6953, -54.4367, 'Iguazú', 'Misiones', 'Argentina'),
    post('maya', 'Ha Long Bay by kayak', nature, 'Limestone islands rising out of green water.', 1, 20.9101, 107.1839, 'Ha Long', 'Quảng Ninh', 'Vietnam'),
    post('maya', 'Navagio shipwreck beach', beach, 'Only reachable by boat.', 1, 37.8594, 20.6243, 'Navagio', 'Zakynthos', 'Greece'),
    post('maya', 'Maya Bay at dawn', beach, 'Go on the first boat, before the crowds.', 1, 7.6783, 98.7671, 'Phi Phi Leh', 'Krabi', 'Thailand'),
    post('maya', 'Copacabana boardwalk', beach, 'Coconut water and wave-pattern tiles.', 1, -22.9711, -43.1822, 'Copacabana', 'Rio de Janeiro', 'Brazil'),
    post('maya', 'Yosemite Valley camp', camp, 'El Capitan right outside the tent.', 1, 37.7456, -119.5936, 'Yosemite Valley', 'California', 'USA'),
    post('maya', 'Sahara camp near Merzouga', camp, 'Camel ride in, stars all night.', 1, 31.0802, -4.0133, 'Erg Chebbi', 'Merzouga', 'Morocco'),
    post('maya', 'Lofoten beach camp', camp, 'Midnight sun over the fjord.', 1, 68.2342, 13.6110, 'Haukland', 'Lofoten', 'Norway'),
    post('maya', 'Times Square at night', night, 'Brighter at midnight than at noon.', 1, 40.7580, -73.9855, 'Midtown', 'New York', 'USA'),
    post('maya', 'Namsan Tower lights', night, 'The whole of Seoul glowing below.', 1, 37.5512, 126.9882, 'Namsan', 'Seoul', 'South Korea'),
    post('maya', 'The Las Vegas Strip', night, 'Walk it once, end to end.', 1, 36.1147, -115.1728, 'The Strip', 'Las Vegas', 'USA'),
    post('maya', 'Melbourne laneway coffee', cafe, 'Find the café with no sign.', 1, -37.8136, 144.9631, 'Degraves Street', 'Melbourne', 'Australia'),
    post('maya', 'Café Central', cafe, 'Melange and apple strudel under the arches.', 1, 48.2104, 16.3655, 'Innere Stadt', 'Vienna', 'Austria'),
    post('maya', 'Old Quarter egg coffee', cafe, 'Sweet, rich and only in Hanoi.', 1, 21.0340, 105.8500, 'Hoàn Kiếm', 'Hanoi', 'Vietnam'),
    post('maya', 'Oia sunset', view, 'Everyone claps when the sun goes down.', 1, 36.4618, 25.3753, 'Oia', 'Santorini', 'Greece'),
    post('maya', 'Arthur\'s Seat', view, 'A short climb, the whole city below.', 1, 55.9441, -3.1618, 'Holyrood', 'Edinburgh', 'UK'),
    post('maya', 'Christ the Redeemer', view, 'Go early, the clouds roll in by noon.', 1, -22.9519, -43.2105, 'Corcovado', 'Rio de Janeiro', 'Brazil'),
    post('maya', 'Lion\'s Head at sunrise', view, 'Chains near the top, views all around.', 1, -33.9353, 18.3891, 'Signal Hill', 'Cape Town', 'South Africa'),
    post('maya', 'Fushimi Inari gates', walk, 'Keep climbing; the crowds thin out.', 1, 34.9671, 135.7727, 'Fushimi', 'Kyoto', 'Japan'),
    post('maya', 'Amsterdam canal ring', walk, 'Get lost, every bridge looks the same.', 1, 52.3676, 4.9041, 'Grachtengordel', 'Amsterdam', 'Netherlands'),
    post('maya', 'San Telmo Sunday market', walk, 'Tango in the square by the afternoon.', 1, -34.6212, -58.3731, 'San Telmo', 'Buenos Aires', 'Argentina'),
  ];
}
