import '../../../core/l10n/l10n.dart';
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
    headline: _headline(mine.name, other.name, shared, similarEnergy),
    sharedLikes: shared,
    similarEnergy: similarEnergy,
  );
}

String _headline(String a, String b, List<String> shared, bool similarEnergy) {
  final likes = _joinLikes(shared);
  if (similarEnergy && likes.isNotEmpty) {
    return L10n.tr(
      '✨ $a i $b imaju sličan nivo energije i oboje vole $likes!',
      '✨ $a and $b have a similar energy level and both love $likes!',
    );
  }
  if (likes.isNotEmpty) {
    return L10n.tr(
      '✨ $a i $b oboje vole $likes!',
      '✨ $a and $b both love $likes!',
    );
  }
  if (similarEnergy) {
    return L10n.tr(
      '✨ $a i $b imaju sličan nivo energije!',
      '✨ $a and $b have a similar energy level!',
    );
  }
  return L10n.tr(
    '✨ $a i $b mogu da se dopune — upoznajte se u šetnji!',
    '✨ $a and $b could complement each other — meet on a walk!',
  );
}

String _joinLikes(List<String> tags) {
  if (tags.isEmpty) {
    return '';
  }
  final phrases = [for (final tag in tags) _likePhrase(tag)];
  final andWord = L10n.tr('i', 'and');
  if (phrases.length == 1) {
    return phrases.first;
  }
  if (phrases.length == 2) {
    return '${phrases[0]} $andWord ${phrases[1]}';
  }
  return '${phrases.sublist(0, phrases.length - 1).join(', ')} $andWord ${phrases.last}';
}

String _likePhrase(String tag) {
  switch (tag) {
    case 'Šetnje':
      return L10n.tr('duge šetnje', 'long walks');
    case 'Trčanje':
      return L10n.tr('trčanje', 'running');
    case 'Igru':
      return L10n.tr('igru', 'play');
    case 'Male pse':
      return L10n.tr('male pse', 'small dogs');
    case 'Velike pse':
      return L10n.tr('velike pse', 'large dogs');
    case 'Mirne pse':
      return L10n.tr('mirne pse', 'calm dogs');
    default:
      return tag.toLowerCase();
  }
}
