String normalizeForSearch(String value) {
  var output = value.toLowerCase().trim();

  const accentMap = {
    'a': ['a', 'á', 'à', 'â', 'ã', 'ä'],
    'e': ['e', 'é', 'è', 'ê', 'ë'],
    'i': ['i', 'í', 'ì', 'î', 'ï'],
    'o': ['o', 'ó', 'ò', 'ô', 'õ', 'ö'],
    'u': ['u', 'ú', 'ù', 'û', 'ü'],
    'c': ['c', 'ç'],
    'n': ['n', 'ñ'],
  };

  for (final entry in accentMap.entries) {
    for (final variant in entry.value) {
      if (variant == entry.key) continue;
      output = output.replaceAll(variant, entry.key);
    }
  }

  output = output.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
  return output;
}

List<String> queryTokens(String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return const <String>[];
  return normalized.split(' ').where((token) => token.isNotEmpty).toList();
}

String normalizeLookupKey(String value) {
  return normalizeForSearch(value).replaceAll(' ', '_');
}

bool matchesAllTokens(String haystack, List<String> tokens) {
  if (tokens.isEmpty) return true;
  final normalized = normalizeForSearch(haystack);
  for (final token in tokens) {
    if (!normalized.contains(token)) return false;
  }
  return true;
}
