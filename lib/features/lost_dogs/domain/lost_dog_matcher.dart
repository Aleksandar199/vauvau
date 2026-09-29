import 'lost_dog.dart';

abstract final class LostDogMatcher {
  static const _stopWords = {
    'i',
    'u',
    'na',
    'je',
    'se',
    'za',
    'od',
    'da',
    'sa',
    'ili',
    'kao',
    'gde',
    'ovaj',
    'taj',
    'pas',
    'psa',
    'ima',
    'bio',
    'bila',
    'oko',
    'kod',
    'preko',
  };

  static List<LostDog> matchesFor(LostDog found, List<LostDog> catalog) {
    if (!found.isFoundListing || !found.isActive) {
      return const [];
    }
    final scored = <({LostDog dog, int score})>[];
    for (final lost in catalog) {
      if (!lost.isMissing || lost.id == found.id) {
        continue;
      }
      final score = _score(found, lost);
      if (score > 0) {
        scored.add((dog: lost, score: score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final item in scored) item.dog];
  }

  static int _score(LostDog found, LostDog lost) {
    if (!_samePlace(found.city, lost.city)) {
      return 0;
    }
    var score = 1;
    final sameHood = _samePlace(found.neighborhood, lost.neighborhood);
    if (sameHood) {
      score += 4;
    }
    if (_breedsMatch(found.breed, lost.breed)) {
      score += 3;
    }
    if (_keywordsOverlap(found, lost)) {
      score += 2;
    }
    if (score < 2 && !sameHood) {
      return 0;
    }
    return score;
  }

  static bool _samePlace(String a, String b) {
    final left = _norm(a);
    final right = _norm(b);
    return left.isNotEmpty && left == right;
  }

  static bool _breedsMatch(String a, String b) {
    final left = _norm(a);
    final right = _norm(b);
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    if (_isUnknownBreed(left) || _isUnknownBreed(right)) {
      return false;
    }
    return left == right || left.contains(right) || right.contains(left);
  }

  static bool _isUnknownBreed(String value) {
    return value == 'nije sigurno' || value == 'drugo' || value == 'nepoznato';
  }

  static bool _keywordsOverlap(LostDog found, LostDog lost) {
    final left = _tokens('${found.description} ${found.dogName} ${found.breed}');
    final right = _tokens('${lost.description} ${lost.dogName} ${lost.breed}');
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    return left.intersection(right).isNotEmpty;
  }

  static Set<String> _tokens(String raw) {
    return {
      for (final part in _norm(raw).split(RegExp(r'[^a-zčćžšđ0-9]+')))
        if (part.length >= 4 && !_stopWords.contains(part)) part,
    };
  }

  static String _norm(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
