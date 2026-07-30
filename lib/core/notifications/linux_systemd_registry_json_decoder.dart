import 'linux_systemd_schedule_registry_exception.dart';

final class LinuxSystemdRegistryJsonDecoder {
  const LinuxSystemdRegistryJsonDecoder();

  Object? decode(String source) {
    return _LinuxSystemdRegistryJsonParser(source).parse();
  }
}

final class _LinuxSystemdRegistryJsonParser {
  _LinuxSystemdRegistryJsonParser(this._source);

  final String _source;
  int _index = 0;

  Object? parse() {
    _skipWhitespace();
    if (_isAtEnd) {
      _malformed();
    }

    final value = _parseValue();
    _skipWhitespace();

    if (!_isAtEnd) {
      _malformed();
    }

    return value;
  }

  Object? _parseValue() {
    _skipWhitespace();

    if (_isAtEnd) {
      _malformed();
    }

    return switch (_source.codeUnitAt(_index)) {
      0x7b => _parseObject(),
      0x5b => _parseArray(),
      0x22 => _parseString(),
      0x74 => _parseLiteral('true', true),
      0x66 => _parseLiteral('false', false),
      0x6e => _parseLiteral('null', null),
      0x2d => _parseNumber(),
      final codeUnit when _isDigit(codeUnit) => _parseNumber(),
      _ => _malformed(),
    };
  }

  Map<String, Object?> _parseObject() {
    _expectCodeUnit(0x7b);
    _skipWhitespace();

    final result = <String, Object?>{};
    final keys = <String>{};

    if (_consumeCodeUnit(0x7d)) {
      return result;
    }

    while (true) {
      _skipWhitespace();
      if (_isAtEnd || _source.codeUnitAt(_index) != 0x22) {
        _malformed();
      }

      final key = _parseString();
      if (!keys.add(key)) {
        _malformed();
      }

      _skipWhitespace();
      _expectCodeUnit(0x3a);
      result[key] = _parseValue();
      _skipWhitespace();

      if (_consumeCodeUnit(0x7d)) {
        return result;
      }

      _expectCodeUnit(0x2c);
    }
  }

  List<Object?> _parseArray() {
    _expectCodeUnit(0x5b);
    _skipWhitespace();

    final result = <Object?>[];

    if (_consumeCodeUnit(0x5d)) {
      return result;
    }

    while (true) {
      result.add(_parseValue());
      _skipWhitespace();

      if (_consumeCodeUnit(0x5d)) {
        return result;
      }

      _expectCodeUnit(0x2c);
    }
  }

  String _parseString() {
    _expectCodeUnit(0x22);
    final buffer = StringBuffer();

    while (!_isAtEnd) {
      final codeUnit = _source.codeUnitAt(_index);
      _index += 1;

      if (codeUnit == 0x22) {
        return buffer.toString();
      }

      if (codeUnit < 0x20) {
        _malformed();
      }

      if (codeUnit != 0x5c) {
        buffer.writeCharCode(codeUnit);
        continue;
      }

      if (_isAtEnd) {
        _malformed();
      }

      final escape = _source.codeUnitAt(_index);
      _index += 1;

      switch (escape) {
        case 0x22:
          buffer.writeCharCode(0x22);
          continue;
        case 0x5c:
          buffer.writeCharCode(0x5c);
          continue;
        case 0x2f:
          buffer.writeCharCode(0x2f);
          continue;
        case 0x62:
          buffer.writeCharCode(0x08);
          continue;
        case 0x66:
          buffer.writeCharCode(0x0c);
          continue;
        case 0x6e:
          buffer.writeCharCode(0x0a);
          continue;
        case 0x72:
          buffer.writeCharCode(0x0d);
          continue;
        case 0x74:
          buffer.writeCharCode(0x09);
          continue;
        case 0x75:
          final first = _parseHexCodeUnit();

          if (_isHighSurrogate(first)) {
            if (_remainingLength < 6 ||
                _source.codeUnitAt(_index) != 0x5c ||
                _source.codeUnitAt(_index + 1) != 0x75) {
              _malformed();
            }

            _index += 2;
            final second = _parseHexCodeUnit();
            if (!_isLowSurrogate(second)) {
              _malformed();
            }

            final codePoint =
                0x10000 + ((first - 0xd800) << 10) + (second - 0xdc00);
            buffer.writeCharCode(codePoint);
          } else if (_isLowSurrogate(first)) {
            _malformed();
          } else {
            buffer.writeCharCode(first);
          }
          continue;
        default:
          _malformed();
      }
    }

    _malformed();
  }

  num _parseNumber() {
    final start = _index;
    var hasFraction = false;
    var hasExponent = false;

    _consumeCodeUnit(0x2d);

    if (_isAtEnd) {
      _malformed();
    }

    if (_consumeCodeUnit(0x30)) {
      if (!_isAtEnd && _isDigit(_source.codeUnitAt(_index))) {
        _malformed();
      }
    } else {
      if (_isAtEnd || !_isOneToNine(_source.codeUnitAt(_index))) {
        _malformed();
      }

      _index += 1;
      while (!_isAtEnd && _isDigit(_source.codeUnitAt(_index))) {
        _index += 1;
      }
    }

    if (_consumeCodeUnit(0x2e)) {
      hasFraction = true;

      if (_isAtEnd || !_isDigit(_source.codeUnitAt(_index))) {
        _malformed();
      }

      while (!_isAtEnd && _isDigit(_source.codeUnitAt(_index))) {
        _index += 1;
      }
    }

    if (!_isAtEnd &&
        (_source.codeUnitAt(_index) == 0x65 ||
            _source.codeUnitAt(_index) == 0x45)) {
      hasExponent = true;
      _index += 1;

      if (!_isAtEnd &&
          (_source.codeUnitAt(_index) == 0x2b ||
              _source.codeUnitAt(_index) == 0x2d)) {
        _index += 1;
      }

      if (_isAtEnd || !_isDigit(_source.codeUnitAt(_index))) {
        _malformed();
      }

      while (!_isAtEnd && _isDigit(_source.codeUnitAt(_index))) {
        _index += 1;
      }
    }

    final lexeme = _source.substring(start, _index);

    if (!hasFraction && !hasExponent) {
      final value = int.tryParse(lexeme);
      if (value == null) {
        _malformed();
      }

      return value;
    }

    final value = double.tryParse(lexeme);
    if (value == null || !value.isFinite) {
      _malformed();
    }

    return value;
  }

  T _parseLiteral<T>(String token, T value) {
    if (!_source.startsWith(token, _index)) {
      _malformed();
    }

    _index += token.length;
    return value;
  }

  int _parseHexCodeUnit() {
    if (_remainingLength < 4) {
      _malformed();
    }

    var value = 0;

    for (var offset = 0; offset < 4; offset += 1) {
      final digit = _hexValue(_source.codeUnitAt(_index + offset));
      if (digit < 0) {
        _malformed();
      }

      value = (value << 4) | digit;
    }

    _index += 4;
    return value;
  }

  void _skipWhitespace() {
    while (!_isAtEnd) {
      final codeUnit = _source.codeUnitAt(_index);

      if (codeUnit != 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0a &&
          codeUnit != 0x0d) {
        return;
      }

      _index += 1;
    }
  }

  void _expectCodeUnit(int expected) {
    if (!_consumeCodeUnit(expected)) {
      _malformed();
    }
  }

  bool _consumeCodeUnit(int expected) {
    if (_isAtEnd || _source.codeUnitAt(_index) != expected) {
      return false;
    }

    _index += 1;
    return true;
  }

  Never _malformed() {
    throw LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.decode,
      failure: LinuxSystemdScheduleRegistryFailure.malformedJson,
    );
  }

  bool get _isAtEnd => _index >= _source.length;

  int get _remainingLength => _source.length - _index;

  static bool _isDigit(int codeUnit) {
    return codeUnit >= 0x30 && codeUnit <= 0x39;
  }

  static bool _isOneToNine(int codeUnit) {
    return codeUnit >= 0x31 && codeUnit <= 0x39;
  }

  static bool _isHighSurrogate(int codeUnit) {
    return codeUnit >= 0xd800 && codeUnit <= 0xdbff;
  }

  static bool _isLowSurrogate(int codeUnit) {
    return codeUnit >= 0xdc00 && codeUnit <= 0xdfff;
  }

  static int _hexValue(int codeUnit) {
    if (codeUnit >= 0x30 && codeUnit <= 0x39) {
      return codeUnit - 0x30;
    }

    if (codeUnit >= 0x41 && codeUnit <= 0x46) {
      return codeUnit - 0x41 + 10;
    }

    if (codeUnit >= 0x61 && codeUnit <= 0x66) {
      return codeUnit - 0x61 + 10;
    }

    return -1;
  }
}
