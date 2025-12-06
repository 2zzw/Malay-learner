import 'dart:convert';

class Word {
  final String id;
  final String word;
  final String english;
  final String chinese;
  final String phonetic;
  final String category;
  final List<Map<String, dynamic>> sentences;
  final List<Map<String, dynamic>> collocations;

  Word({
    required this.id,
    required this.word,
    required this.english,
    required this.chinese,
    required this.phonetic,
    required this.category,
    required this.sentences,
    required this.collocations,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id']?.toString() ?? '',
      word: json['malay_word']?.toString() ?? '',
      english: json['english_meaning']?.toString() ?? '',
      chinese: json['chinese_meaning']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      sentences: safeParseData(json['sentences'], dataType: 'sentence'),
      collocations: safeParseData(json['collocations'], dataType: 'phrase'),
    );
  }

  static List<Map<String, dynamic>> safeParseData(
    dynamic data, {
    String dataType = 'auto',
  }) {
    try {
      if (data == null) return [];

      if (data is String) {
        return _parseStringData(data, dataType: dataType);
      }

      if (data is List) {
        return _parseListData(data, dataType: dataType);
      }
      try {
        String encoded = jsonEncode(data);
        return safeParseData(encoded, dataType: dataType);
      } catch (_) {
        return [];
      }
    } catch (e, stackTrace) {
      print('WordModel.safeParseData error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseStringData(
    String data, {
    required String dataType,
  }) {
    String trimmed = data.trim();

    if (trimmed.isEmpty) return [];

    try {
      dynamic decoded = jsonDecode(trimmed);

      if (decoded is List) {
        return _parseListData(decoded, dataType: dataType);
      } else {
        print('WordModel._parseStringData: unexpected data type: $decoded');
        return [];
      }
    } catch (e) {
      print('WordModel._parseStringData: parsing failed: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseListData(
    List list, {
    required String dataType,
  }) {
    List<Map<String, dynamic>> result = [];

    for (var item in list) {
      if (item is Map) {
        Map<String, dynamic> parsedItem;

        if (dataType == 'auto') {
          if (_isSentenceStructure(item)) {
            parsedItem = _parseSentenceItem(item);
          } else if (_isPhraseStructure(item)) {
            parsedItem = _parsePhraseItem(item);
          } else {
            parsedItem = _parseGenericMap(item);
          }
        } else if (dataType == 'sentence') {
          parsedItem = _parseSentenceItem(item);
        } else if (dataType == 'phrase') {
          parsedItem = _parsePhraseItem(item);
        } else {
          parsedItem = _parseGenericMap(item);
        }

        if (parsedItem.isNotEmpty) {
          result.add(parsedItem);
        }
      } else if (item is String) {
        var parsed = _tryParseStringItem(item, dataType: dataType);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }

    return result;
  }

  static bool _isSentenceStructure(Map map) {
    return map.containsKey('malay') &&
        map.containsKey('english') &&
        map.containsKey('chinese');
  }

  static bool _isPhraseStructure(Map map) {
    return map.containsKey('phrase') && map.containsKey('meaning');
  }

  static Map<String, dynamic> _parseSentenceItem(Map map) {
    try {
      return {
        'type': 'sentence',
        'malay': map['malay']?.toString() ?? '',
        'english': map['english']?.toString() ?? '',
        'chinese': map['chinese']?.toString() ?? '',
        'original': map,
      };
    } catch (e) {
      // ignore: empty_catches
      return {};
    }
  }

  static Map<String, dynamic> _parsePhraseItem(Map map) {
    try {
      String phrase = map['phrase']?.toString() ?? '';

      Map<String, String> meaning = _parseMeaning(map['meaning']);

      return {
        'type': 'phrase',
        'phrase': phrase,
        'english': meaning['english'] ?? '',
        'chinese': meaning['chinese'] ?? '',
        'meaning': meaning,
        'original': map,
      };
    } catch (e) {
      // ignore: empty_catches
      return {};
    }
  }

  static Map<String, String> _parseMeaning(dynamic meaningData) {
    Map<String, String> result = {'english': '', 'chinese': ''};

    try {
      if (meaningData == null) return result;

      if (meaningData is Map) {
        result['english'] = meaningData['english']?.toString() ?? '';
        result['chinese'] = meaningData['chinese']?.toString() ?? '';
        return result;
      }

      if (meaningData is String) {
        String trimmed = meaningData.trim();

        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          try {
            Map<String, dynamic> parsed = jsonDecode(trimmed);
            result['english'] = parsed['english']?.toString() ?? '';
            result['chinese'] = parsed['chinese']?.toString() ?? '';
            return result;
          } catch (e) {}
        }

        return _parseSimpleMeaningFormat(trimmed);
      }
    } catch (e) {
      // ignore: empty_catches
    }

    return result;
  }

  static Map<String, String> _parseSimpleMeaningFormat(String text) {
    Map<String, String> result = {'english': '', 'chinese': ''};

    try {
      String cleaned = text.replaceAll(RegExp(r'[{}"]'), '').trim();

      RegExp englishReg = RegExp(r'english:\s*([^,}]+)', caseSensitive: false);
      RegExp chineseReg = RegExp(r'chinese:\s*([^,}]+)', caseSensitive: false);

      Match? englishMatch = englishReg.firstMatch(cleaned);
      Match? chineseMatch = chineseReg.firstMatch(cleaned);

      if (englishMatch != null)
        result['english'] = englishMatch.group(1)!.trim();
      if (chineseMatch != null)
        result['chinese'] = chineseMatch.group(1)!.trim();

      if (result['english']!.isEmpty || result['chinese']!.isEmpty) {
        List<String> parts = cleaned.split(',');
        if (parts.length >= 2) {
          for (var part in parts) {
            if (part.toLowerCase().contains('english') ||
                result['english']!.isEmpty) {
              result['english'] = part.replaceAll('english:', '').trim();
            }
            if (part.toLowerCase().contains('chinese') ||
                result['chinese']!.isEmpty) {
              result['chinese'] = part.replaceAll('chinese:', '').trim();
            }
          }
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }

    return result;
  }

  static Map<String, dynamic> _parseGenericMap(Map map) {
    Map<String, dynamic> result = {};

    try {
      map.forEach((key, value) {
        if (key != null) {
          result[key.toString()] = value;
        }
      });

      if (result.containsKey('malay') &&
          result.containsKey('english') &&
          result.containsKey('chinese')) {
        result['type'] = 'sentence';
      } else if (result.containsKey('phrase')) {
        result['type'] = 'phrase';
      }
    } catch (e) {
      // ignore: empty_catches
    }

    return result;
  }

  static Map<String, dynamic>? _tryParseStringItem(
    String item, {
    required String dataType,
  }) {
    try {
      if (item.trim().startsWith('{') && item.trim().endsWith('}')) {
        Map parsed = jsonDecode(item.trim());
        if (dataType == 'sentence') {
          return _parseSentenceItem(parsed);
        } else if (dataType == 'phrase') {
          return _parsePhraseItem(parsed);
        } else {
          return _parseGenericMap(parsed);
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }

    return null;
  }
}
