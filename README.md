# Viaggio

A Flutter app for saving the places you love and sharing them with friends.
*Viaggio* is Italian for "journey".

## Features

- **Your places**: save a place with photos, a category, a note and its
  location, and see them all on a map.
- **Discover**: a feed of places other people share. Tap the search icon to
  search, and filter by category from the search bar.
- **Profiles**: follow people, see follower and following counts, and earn
  badges for the places you save.
- **Posts**: comment on a post, share it to other apps, or send it into one
  or more chats at once, where it shows as a card that opens the post.
- **Messages**: one-to-one chats and group chats of up to 9 people. A group's
  creator is its admin: only they can change its name and photo or remove
  members.
- **Languages**: English, Arabic and Turkish, with light and dark mode.

## Built with

- [Flutter](https://flutter.dev) and Dart
- [Riverpod](https://riverpod.dev) for state
- [Firebase](https://firebase.google.com): Authentication and Cloud Firestore
- [flutter_map](https://pub.dev/packages/flutter_map) for maps

## Getting started

You need [Flutter](https://docs.flutter.dev/get-started/install) and a
Firebase project of your own. The Firebase config files are not in this
repository.

1. Get the packages:

   ```bash
   flutter pub get
   ```

2. Connect your Firebase project (this creates `lib/firebase_options.dart`
   and the platform config files):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   In the Firebase console, turn on **Authentication** and **Cloud
   Firestore**.

3. Deploy the Firestore security rules and indexes:

   ```bash
   firebase deploy --only firestore
   ```

4. Run the app:

   ```bash
   flutter run
   ```

Debug and profile builds add sample people, posts and a sample group chat,
so the app is not empty while you try it. Release builds leave them out.

## Project structure

```
lib/
  screens/    app screens: Discover, Map, Messages, Account, profiles, chats
  widgets/    shared UI pieces
  providers/  Riverpod providers and Firestore access
  models/     places and badges
  services/   photos and address lookup
  data/       sample content for debug builds
  l10n/       translations (English, Arabic, Turkish)
  theme/      colors, text styles and spacing
firestore.rules   who can read and change what
test/             widget tests
```

## Tests

```bash
flutter test
```
