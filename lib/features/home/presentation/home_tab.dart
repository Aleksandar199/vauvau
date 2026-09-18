import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;

  void showDiscover() => state = 0;

  void showMap() => state = 1;

  void showMessages() => state = 2;

  void showProfile() => state = 3;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabIndex, int>(HomeTabIndex.new);
