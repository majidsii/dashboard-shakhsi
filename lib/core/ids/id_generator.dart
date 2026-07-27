import 'package:uuid/uuid.dart';

abstract interface class IdGenerator {
  String next();
}

final class UuidV7IdGenerator implements IdGenerator {
  const UuidV7IdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String next() => _uuid.v7();
}

final class SequenceIdGenerator implements IdGenerator {
  SequenceIdGenerator({this.prefix = 'test'});

  final String prefix;
  int _value = 0;

  @override
  String next() {
    _value += 1;
    return '$prefix-$_value';
  }
}
