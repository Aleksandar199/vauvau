import 'discover_profile.dart';

class CompatibilityInsight {
  const CompatibilityInsight({
    required this.headline,
    required this.sharedLikes,
    required this.similarEnergy,
  });

  final String headline;
  final List<String> sharedLikes;
  final bool similarEnergy;
}

CompatibilityInsight describeCompatibility({
  required DiscoverProfile mine,
  required DiscoverProfile other,
}) {
  final shared = [
    for (final tag in mine.likesTags)
      if (other.likesTags.contains(tag) && !other.dislikesTags.contains(tag))
        tag,
  ];
  final similarEnergy = mine.energyLabel == other.energyLabel;
  return CompatibilityInsight(
    headline: _headline(
      mine.name,
      other.name,
      shared,
      similarEnergy,
    ),
    sharedLikes: shared,
    similarEnergy: similarEnergy,
  );
}

String _headline(
  String a,
  String b,
  List<String> shared,
  bool similarEnergy,
) {
  final likes = _joinLikes(shared);
  if (similarEnergy && likes.isNotEmpty) {
    return '✨ $a i $b imaju sličan nivo energije i oboje vole $likes!';
  }
  if (likes.isNotEmpty) {
    return '✨ $a i $b oboje vole $likes!';
  }
  if (similarEnergy) {
    return '✨ $a i $b imaju sličan nivo energije!';
  }
  return '✨ $a i $b mogu da se dopune — upoznajte se u šetnji!';
}

String _joinLikes(List<String> tags) {
  if (tags.isEmpty) {
    return '';
  }
  final phrases = [for (final tag in tags) _likePhrase(tag)];
  if (phrases.length == 1) {
    return phrases.first;
  }
  if (phrases.length == 2) {
    return '${phrases[0]} i ${phrases[1]}';
  }
  return '${phrases.sublist(0, phrases.length - 1).join(', ')} i ${phrases.last}';
}

String _likePhrase(String tag) {
  switch (tag) {
    case 'Šetnje':
      return 'duge šetnje';
    case 'Trčanje':
      return 'trčanje';
    case 'Igru':
      return 'igru';
    case 'Male pse':
      return 'male pse';
    case 'Velike pse':
      return 'velike pse';
    case 'Mirne pse':
      return 'mirne pse';
    default:
      return tag.toLowerCase();
  }
}
