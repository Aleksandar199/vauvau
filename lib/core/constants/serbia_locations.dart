class Neighborhood {
  const Neighborhood({required this.id, required this.name});

  final String id;
  final String name;
}

class CityLocation {
  const CityLocation({
    required this.id,
    required this.name,
    required this.neighborhoods,
  });

  final String id;
  final String name;
  final List<Neighborhood> neighborhoods;
}

abstract final class SerbiaLocations {
  static const String noviSadId = 'novi_sad';
  static const String nisId = 'nis';
  static const String kragujevacId = 'kragujevac';
  static const String zrenjaninId = 'zrenjanin';
  static const String suboticaId = 'subotica';
  static const String customNeighborhoodId = 'custom';
  static const String customNeighborhoodLabel = 'Ostalo / Ručni unos';

  static const List<CityLocation> cities = [
    CityLocation(
      id: noviSadId,
      name: 'Novi Sad',
      neighborhoods: [
        Neighborhood(id: 'liman_1', name: 'Liman 1'),
        Neighborhood(id: 'liman_2', name: 'Liman 2'),
        Neighborhood(id: 'liman_3', name: 'Liman 3'),
        Neighborhood(id: 'liman_4', name: 'Liman 4'),
        Neighborhood(id: 'grbavica', name: 'Grbavica'),
        Neighborhood(id: 'centar', name: 'Centar'),
        Neighborhood(id: 'detelinara', name: 'Detelinara'),
        Neighborhood(id: 'novo_naselje', name: 'Novo Naselje'),
        Neighborhood(id: 'telep', name: 'Telep'),
        Neighborhood(id: 'podbara', name: 'Podbara'),
        Neighborhood(id: 'rotkvarija', name: 'Rotkvarija'),
        Neighborhood(id: 'salajka', name: 'Salajka'),
        Neighborhood(id: 'banatic', name: 'Banatić'),
        Neighborhood(id: 'sajmiste', name: 'Sajmište'),
        Neighborhood(id: 'avijaticarsko_naselje', name: 'Avijatičarsko Naselje'),
        Neighborhood(id: 'adamovicevo_naselje', name: 'Adamovićevo Naselje'),
        Neighborhood(id: 'petrovaradin', name: 'Petrovaradin'),
        Neighborhood(id: 'sremska_kamenica', name: 'Sremska Kamenica'),
        Neighborhood(id: 'futog', name: 'Futog'),
        Neighborhood(id: 'veternik', name: 'Veternik'),
        Neighborhood(id: 'adice', name: 'Adice'),
        Neighborhood(id: 'klisa', name: 'Klisa'),
        Neighborhood(id: 'vidovdansko_naselje', name: 'Vidovdansko Naselje'),
        Neighborhood(id: 'slana_bara', name: 'Slana Bara'),
      ],
    ),
    CityLocation(
      id: 'beograd',
      name: 'Beograd',
      neighborhoods: [
        Neighborhood(id: 'altina', name: 'Altina'),
        Neighborhood(id: 'autokomanda', name: 'Autokomanda'),
        Neighborhood(id: 'banjica', name: 'Banjica'),
        Neighborhood(id: 'banovo_brdo', name: 'Banovo brdo'),
        Neighborhood(id: 'barajevo', name: 'Barajevo'),
        Neighborhood(id: 'batajnica', name: 'Batajnica'),
        Neighborhood(id: 'bele_vode', name: 'Bele vode'),
        Neighborhood(id: 'bezanijska_kosa', name: 'Bežanijska kosa'),
        Neighborhood(id: 'borca', name: 'Borča'),
        Neighborhood(id: 'brace_jerkovic', name: 'Braće Jerković'),
        Neighborhood(id: 'cerak', name: 'Cerak'),
        Neighborhood(id: 'crveni_krst_bg', name: 'Crveni krst'),
        Neighborhood(id: 'cukarica', name: 'Čukarica'),
        Neighborhood(id: 'dedinje', name: 'Dedinje'),
        Neighborhood(id: 'dorcol', name: 'Dorćol'),
        Neighborhood(id: 'dusanovac', name: 'Dušanovac'),
        Neighborhood(id: 'djeram', name: 'Đeram'),
        Neighborhood(id: 'galenika', name: 'Galenika'),
        Neighborhood(id: 'grocka', name: 'Grocka'),
        Neighborhood(id: 'julino_brdo', name: 'Julino brdo'),
        Neighborhood(id: 'kanarevo_brdo', name: 'Kanarevo brdo'),
        Neighborhood(id: 'karaburma', name: 'Karaburma'),
        Neighborhood(id: 'konjarnik', name: 'Konjarnik'),
        Neighborhood(id: 'kosutnjak', name: 'Košutnjak'),
        Neighborhood(id: 'kotez', name: 'Kotež'),
        Neighborhood(id: 'krnjaca', name: 'Krnjača'),
        Neighborhood(id: 'kumodraz', name: 'Kumodraž'),
        Neighborhood(id: 'labudovo_brdo', name: 'Labudovo brdo'),
        Neighborhood(id: 'lazarevac', name: 'Lazarevac'),
        Neighborhood(id: 'ledine', name: 'Ledine'),
        Neighborhood(id: 'medakovic', name: 'Medaković'),
        Neighborhood(id: 'mirijevo', name: 'Mirijevo'),
        Neighborhood(id: 'mladenovac', name: 'Mladenovac'),
        Neighborhood(id: 'neimar', name: 'Neimar'),
        Neighborhood(id: 'novi_beograd', name: 'Novi Beograd'),
        Neighborhood(id: 'obrenovac', name: 'Obrenovac'),
        Neighborhood(id: 'ovca', name: 'Ovča'),
        Neighborhood(id: 'palilula_bg', name: 'Palilula'),
        Neighborhood(id: 'rakovica', name: 'Rakovica'),
        Neighborhood(id: 'resnik', name: 'Resnik'),
        Neighborhood(id: 'savamala', name: 'Savamala'),
        Neighborhood(id: 'savski_venac', name: 'Savski venac'),
        Neighborhood(id: 'senjak', name: 'Senjak'),
        Neighborhood(id: 'sopot', name: 'Sopot'),
        Neighborhood(id: 'stari_grad_bg', name: 'Stari grad'),
        Neighborhood(id: 'surcin', name: 'Surčin'),
        Neighborhood(id: 'sumice', name: 'Šumice'),
        Neighborhood(id: 'topcider', name: 'Topčider'),
        Neighborhood(id: 'vidikovac', name: 'Vidikovac'),
        Neighborhood(id: 'visnjica', name: 'Višnjica'),
        Neighborhood(id: 'vozdovac', name: 'Voždovac'),
        Neighborhood(id: 'vracar', name: 'Vračar'),
        Neighborhood(id: 'zemun', name: 'Zemun'),
        Neighborhood(id: 'zemun_polje', name: 'Zemun polje'),
        Neighborhood(id: 'zvezdara', name: 'Zvezdara'),
        Neighborhood(id: 'zarkovo', name: 'Žarkovo'),
      ],
    ),
    CityLocation(
      id: nisId,
      name: 'Niš',
      neighborhoods: [
        Neighborhood(id: 'nis_centar', name: 'Centar'),
        Neighborhood(id: 'medijana', name: 'Medijana'),
        Neighborhood(id: 'palilula_nis', name: 'Palilula'),
        Neighborhood(id: 'pantelej', name: 'Pantelej'),
        Neighborhood(id: 'crveni_krst', name: 'Crveni Krst'),
        Neighborhood(id: 'niska_banja', name: 'Niška Banja'),
        Neighborhood(id: 'durlan', name: 'Durlan'),
        Neighborhood(id: 'bulevar_nemanjica', name: 'Bulevar Nemanjića'),
        Neighborhood(id: 'cair', name: 'Čair'),
        Neighborhood(id: 'tvrdjava', name: 'Tvrđava'),
        Neighborhood(id: 'duvaniste', name: 'Duvanište'),
        Neighborhood(id: 'ledena_stena', name: 'Ledena Stena'),
        Neighborhood(id: 'apelovac', name: 'Apelovac'),
        Neighborhood(id: 'brzi_brod', name: 'Brzi Brod'),
      ],
    ),
    CityLocation(
      id: kragujevacId,
      name: 'Kragujevac',
      neighborhoods: [
        Neighborhood(id: 'kg_centar', name: 'Centar'),
        Neighborhood(id: 'kg_aerodrom', name: 'Aerodrom'),
        Neighborhood(id: 'erdoglija', name: 'Erdoglija'),
        Neighborhood(id: 'pivara', name: 'Pivara'),
        Neighborhood(id: 'palilule_kg', name: 'Palilule'),
        Neighborhood(id: 'bresnica', name: 'Bresnica'),
        Neighborhood(id: 'stanovo', name: 'Stanovo'),
        Neighborhood(id: 'vasariste', name: 'Vašarište'),
        Neighborhood(id: 'ilicevo', name: 'Ilićevo'),
        Neighborhood(id: 'bubanj', name: 'Bubanj'),
        Neighborhood(id: 'denino_brdo', name: 'Denino brdo'),
        Neighborhood(id: 'metino_brdo', name: 'Metino brdo'),
        Neighborhood(id: 'sumarice', name: 'Šumarice'),
        Neighborhood(id: 'susica', name: 'Sušica'),
        Neighborhood(id: 'stara_radnicka_kolonija', name: 'Stara radnička kolonija'),
      ],
    ),
    // Gradska naselja Zrenjanina (sr.wikipedia.org, „Zrenjanin“ – gradska
    // naselja / mesne zajednice). Okolna sela nisu gradski kvartovi.
    CityLocation(
      id: zrenjaninId,
      name: 'Zrenjanin',
      neighborhoods: [
        Neighborhood(id: 'zr_centar', name: 'Centar'),
        Neighborhood(id: 'zr_bagljas', name: 'Bagljaš'),
        Neighborhood(id: 'zr_berbersko', name: 'Berbersko'),
        Neighborhood(id: 'zr_bolnica', name: 'Bolnica'),
        Neighborhood(id: 'zr_brigadira_ristica', name: 'Brigadira Ristića'),
        Neighborhood(id: 'zr_budzak', name: 'Budžak'),
        Neighborhood(id: 'zr_budzin_bulevar', name: 'Budžin bulevar'),
        Neighborhood(id: 'zr_cetvrti_jul', name: '4. jul'),
        Neighborhood(id: 'zr_contika', name: 'Čontika'),
        Neighborhood(id: 'zr_dolja', name: 'Dolja'),
        Neighborhood(id: 'zr_duvanika', name: 'Duvanika'),
        Neighborhood(id: 'zr_gradnulica', name: 'Gradnulica'),
        Neighborhood(id: 'zr_lesnina', name: 'Lesnina'),
        Neighborhood(id: 'zr_mala_amerika', name: 'Mala Amerika'),
        Neighborhood(id: 'zr_mickej', name: 'Mičkej'),
        Neighborhood(id: 'zr_muzlja', name: 'Mužlja'),
        Neighborhood(id: 'zr_nova_kolonija', name: 'Nova Kolonija'),
        Neighborhood(id: 'zr_putnikovo', name: 'Putnikovo'),
        Neighborhood(id: 'zr_ruza_sulman', name: 'Ruža Šulman'),
        Neighborhood(id: 'zr_sumica', name: 'Šumica'),
        Neighborhood(id: 'zr_zeleno_polje', name: 'Zeleno Polje'),
        Neighborhood(id: 'zr_zitni_trg', name: 'Žitni Trg'),
      ],
    ),
    // Gradske mesne zajednice Subotice (sr.wikipedia.org, „Subotica“ –
    // spisak mesnih zajednica). Prigradske (Palić, Bajmok…) nisu uključene.
    CityLocation(
      id: suboticaId,
      name: 'Subotica',
      neighborhoods: [
        Neighborhood(id: 'su_centar_1', name: 'Centar I'),
        Neighborhood(id: 'su_centar_2', name: 'Centar II'),
        Neighborhood(id: 'su_centar_3', name: 'Centar III'),
        Neighborhood(id: 'su_aleksandrovo', name: 'Aleksandrovo'),
        Neighborhood(id: 'su_bajnat', name: 'Bajnat'),
        Neighborhood(id: 'su_dudova_suma', name: 'Dudova šuma'),
        Neighborhood(id: 'su_gat', name: 'Gat'),
        Neighborhood(id: 'su_ker', name: 'Ker'),
        Neighborhood(id: 'su_kertvaros', name: 'Kertvaroš'),
        Neighborhood(id: 'su_makova_sedmica', name: 'Makova sedmica'),
        Neighborhood(id: 'su_mali_bajmok', name: 'Mali Bajmok'),
        Neighborhood(id: 'su_mali_radanovac', name: 'Mali Radanovac'),
        Neighborhood(id: 'su_novi_grad', name: 'Novi Grad'),
        Neighborhood(id: 'su_novo_selo', name: 'Novo Selo'),
        Neighborhood(id: 'su_pescara', name: 'Peščara'),
        Neighborhood(id: 'su_prozivka', name: 'Prozivka'),
        Neighborhood(id: 'su_radanovac', name: 'Radanovac'),
        Neighborhood(id: 'su_radijalac', name: 'Radijalac'),
        Neighborhood(id: 'su_verusic', name: 'Verušić'),
        Neighborhood(id: 'su_zeljeznicko_naselje', name: 'Željezničko naselje'),
        Neighborhood(id: 'su_zorka', name: 'Zorka'),
      ],
    ),
  ];

  static const List<String> adoptionCities = [
    'Novi Sad',
    'Beograd',
    'Niš',
    'Kragujevac',
    'Zrenjanin',
    'Subotica',
    'Ostalo',
  ];

  /// Other names of a city (Hungarian) → city id. Keys are folded
  /// (see [_fold]); Cyrillic spellings are handled by [_fold] itself.
  static const Map<String, String> _cityAliases = {
    'nagybecskerek': zrenjaninId,
    'szabadka': suboticaId,
  };

  static const List<String> noviSadAdoptionNeighborhoods = [
    'Liman 1',
    'Liman 2',
    'Liman 3',
    'Liman 4',
    'Grbavica',
    'Centar (Stari Grad)',
    'Detelinara (Stara i Nova)',
    'Novo Naselje (Bistrica)',
    'Telep',
    'Podbara',
    'Rotkvarija',
    'Salajka',
    'Banatić',
    'Sajmište',
    'Avijatičarsko Naselje',
    'Adamovićevo Naselje',
    'Petrovaradin',
    'Sremska Kamenica',
    'Futog',
    'Veternik',
    'Adice',
    'Klisa',
    'Vidovdansko Naselje',
    'Slana Bara',
  ];

  static List<String> neighborhoodsForAdoptionCity(String city) {
    if (city == 'Novi Sad') {
      return noviSadAdoptionNeighborhoods;
    }
    if (city == 'Beograd') {
      return [
        for (final hood in cityById('beograd')?.neighborhoods ?? const [])
          hood.name,
      ];
    }
    for (final location in cities) {
      if (location.name == city) {
        return [
          for (final hood in location.neighborhoods) hood.name,
          'Ostalo',
        ];
      }
    }
    return const ['Ostalo'];
  }

  static CityLocation get noviSad => cities.first;

  /// City id for a free-text label such as "Niš - Medijana" or "Nis".
  /// Returns null when the label does not start with a known city.
  static String? cityIdForLabel(String raw) {
    final folded = _fold(raw);
    if (folded.isEmpty) {
      return null;
    }
    bool startsWithName(String name) =>
        folded == name ||
        folded.startsWith('$name ') ||
        folded.startsWith('$name,') ||
        folded.startsWith('$name-');
    for (final city in cities) {
      if (startsWithName(_fold(city.name))) {
        return city.id;
      }
    }
    for (final alias in _cityAliases.entries) {
      if (startsWithName(alias.key)) {
        return alias.value;
      }
    }
    return null;
  }

  /// Lowercase Latin form without diacritics, so „Зрењанин“, „ZRENJANIN“ and
  /// „Zrenjanin“ compare equal (`š→s`, `č/ć→c`, `ž→z`, `đ→dj`).
  static String foldName(String value) => _fold(value);

  /// Canonical city id from a stored `cityId` and/or city name.
  static String? resolveCityId(String cityId, String cityName) {
    final byId = cityById(cityId.trim());
    if (byId != null) {
      return byId.id;
    }
    return cityIdForLabel(cityName) ??
        cityIdForLabel(cityId.replaceAll(RegExp(r'[_-]'), ' '));
  }

  static const Map<String, String> _cyrillic = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'ђ': 'dj', 'е': 'e',
    'ж': 'z', 'з': 'z', 'и': 'i', 'ј': 'j', 'к': 'k', 'л': 'l', 'љ': 'lj',
    'м': 'm', 'н': 'n', 'њ': 'nj', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's',
    'т': 't', 'ћ': 'c', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c', 'ч': 'c',
    'џ': 'dz', 'ш': 's',
  };

  static String _fold(String value) {
    final lower = value.trim().toLowerCase();
    final latin = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      latin.write(_cyrillic[char] ?? char);
    }
    return latin
        .toString()
        .replaceAll('š', 's')
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('ž', 'z')
        .replaceAll('đ', 'dj');
  }

  static CityLocation? cityById(String id) {
    for (final city in cities) {
      if (city.id == id) {
        return city;
      }
    }
    return null;
  }

  /// Known neighborhood id in [cityId] for a free-text name, ignoring case,
  /// diacritics and Cyrillic („Багљаш“, „bagljas“ → `zr_bagljas`). Null when
  /// the name is not on the list (it then stays a custom neighborhood).
  static String? neighborhoodIdForLabel(String cityId, String raw) {
    final folded = _fold(raw);
    if (folded.isEmpty) {
      return null;
    }
    for (final hood in cityById(cityId)?.neighborhoods ?? const <Neighborhood>[]) {
      if (_fold(hood.name) == folded) {
        return hood.id;
      }
    }
    return null;
  }

  static bool isCustomNeighborhoodId(String? id) =>
      id == customNeighborhoodId;

  /// True when the stored id is the custom option or not on the city list.
  static bool usesCustomNeighborhood(String cityId, String? neighborhoodId) {
    if (neighborhoodId == null || neighborhoodId.isEmpty) {
      return false;
    }
    if (isCustomNeighborhoodId(neighborhoodId)) {
      return true;
    }
    final city = cityById(cityId);
    if (city == null) {
      return true;
    }
    for (final hood in city.neighborhoods) {
      if (hood.id == neighborhoodId) {
        return false;
      }
    }
    return true;
  }

  /// Dropdown value: known id, or [customNeighborhoodId] when custom/unknown.
  static String? neighborhoodDropdownValue(
    String cityId,
    String? neighborhoodId,
  ) {
    if (neighborhoodId == null || neighborhoodId.isEmpty) {
      return null;
    }
    if (usesCustomNeighborhood(cityId, neighborhoodId)) {
      return customNeighborhoodId;
    }
    return neighborhoodId;
  }

  static String resolveNeighborhoodName({
    required String cityId,
    required String? neighborhoodId,
    String customName = '',
  }) {
    if (usesCustomNeighborhood(cityId, neighborhoodId)) {
      return customName.trim();
    }
    final city = cityById(cityId);
    if (city == null || neighborhoodId == null) {
      return '';
    }
    for (final hood in city.neighborhoods) {
      if (hood.id == neighborhoodId) {
        return hood.name;
      }
    }
    return '';
  }

  static String formatPlace(String cityName, String neighborhoodName) {
    final city = cityName.trim();
    final neighborhood = neighborhoodName.trim();
    if (city.isEmpty && neighborhood.isEmpty) {
      return '';
    }
    if (city.isEmpty) {
      return sanitizeLocationLabel(neighborhood);
    }
    if (neighborhood.isEmpty) {
      return sanitizeLocationLabel(city);
    }
    return sanitizeLocationLabel('$city, $neighborhood');
  }

  static String displayPlace(String raw) {
    return sanitizeLocationLabel(raw);
  }

  /// Turns "Novi Sad Telep Telep" / "Novi Sad · Telep · Telep" into "Novi Sad, Telep".
  static String sanitizeLocationLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed
        .replaceAll('·', ',')
        .replaceAll('•', ',')
        .replaceAll(RegExp(r'\s*[-–/|]\s*'), ',');
    final chunks = <String>[];
    for (final piece in normalized.split(',')) {
      final cleaned = _dedupeRepeatedWords(piece.trim());
      if (cleaned.isEmpty) {
        continue;
      }
      if (chunks.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
        continue;
      }
      if (chunks.isNotEmpty &&
          chunks.last.toLowerCase().contains(cleaned.toLowerCase())) {
        continue;
      }
      chunks.add(cleaned);
    }
    if (chunks.isEmpty) {
      return trimmed;
    }
    if (chunks.length == 1) {
      return _splitCityAndNeighborhood(chunks.first);
    }
    final city = chunks.first;
    final rest = <String>[];
    for (final part in chunks.skip(1)) {
      var neighborhood = part;
      if (neighborhood.toLowerCase().startsWith(city.toLowerCase())) {
        neighborhood =
            neighborhood.substring(city.length).replaceFirst(RegExp(r'^[,·\-\s]+'), '').trim();
      }
      if (neighborhood.isEmpty ||
          neighborhood.toLowerCase() == city.toLowerCase() ||
          city.toLowerCase().contains(neighborhood.toLowerCase())) {
        continue;
      }
      rest.add(neighborhood);
    }
    if (rest.isEmpty) {
      return _splitCityAndNeighborhood(city);
    }
    return '$city, ${rest.join(', ')}';
  }

  static String _dedupeRepeatedWords(String value) {
    final words =
        value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final out = <String>[];
    for (final word in words) {
      if (out.isNotEmpty && out.last.toLowerCase() == word.toLowerCase()) {
        continue;
      }
      out.add(word);
    }
    return out.join(' ');
  }

  static String _splitCityAndNeighborhood(String value) {
    for (final city in cities) {
      final name = city.name;
      if (!value.toLowerCase().startsWith(name.toLowerCase())) {
        continue;
      }
      if (value.length == name.length) {
        return name;
      }
      var rest = value.substring(name.length).trim();
      rest = rest.replaceFirst(RegExp(r'^[,·\-]+'), '').trim();
      rest = _dedupeRepeatedWords(rest);
      if (rest.isEmpty || rest.toLowerCase() == name.toLowerCase()) {
        return name;
      }
      return '$name, $rest';
    }
    return value;
  }
}
