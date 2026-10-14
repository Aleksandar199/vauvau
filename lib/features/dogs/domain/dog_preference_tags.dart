import '../../../core/l10n/l10n.dart';

abstract final class DogPreferenceTags {
  static const List<String> likes = [
    'Šetnje',
    'Trčanje',
    'Igru',
    'Male pse',
    'Velike pse',
    'Mirne pse',
  ];

  static const List<String> dislikes = [
    'Gužvu',
    'Mačke',
    'Velike pse',
    'Decu',
    'Buku',
  ];

  static List<String> sanitize(Iterable<String> raw, List<String> allowed) {
    return [
      for (final tag in raw)
        if (allowed.contains(tag)) tag,
    ];
  }

  /// Display label for a stored preference tag (Serbian key → current locale).
  static String localize(String raw) {
    switch (raw.trim()) {
      case 'Šetnje':
        return L10n.tr('Šetnje', 'Walks');
      case 'Trčanje':
        return L10n.tr('Trčanje', 'Running');
      case 'Igru':
        return L10n.tr('Igru', 'Play');
      case 'Male pse':
        return L10n.tr('Male pse', 'Small dogs');
      case 'Velike pse':
        return L10n.tr('Velike pse', 'Large dogs');
      case 'Mirne pse':
        return L10n.tr('Mirne pse', 'Calm dogs');
      case 'Gužvu':
        return L10n.tr('Gužvu', 'Crowds');
      case 'Mačke':
        return L10n.tr('Mačke', 'Cats');
      case 'Decu':
        return L10n.tr('Decu', 'Kids');
      case 'Buku':
        return L10n.tr('Buku', 'Noise');
      default:
        return raw;
    }
  }
}
