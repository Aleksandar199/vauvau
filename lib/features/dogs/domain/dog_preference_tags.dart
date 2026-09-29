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
}
