import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation: Početna (feed) · Otkrij · Mapa · Poruke · Profil.
/// The app opens on Otkrij; Početna is the Instagram-style feed.
class HomeTabIndex extends Notifier<int> {
  static const int home = 0;
  static const int discover = 1;
  static const int map = 2;
  static const int messages = 3;
  static const int profile = 4;

  @override
  int build() => discover;

  void setIndex(int index) => state = index;

  void showHome() => state = home;

  void showDiscover() => state = discover;

  void showMap() => state = map;

  void showMessages() => state = messages;

  void showProfile() => state = profile;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabIndex, int>(HomeTabIndex.new);
