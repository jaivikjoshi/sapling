String enumToDb(Enum value) {
  return value.name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );
}

T enumFromDb<T extends Enum>(String value, List<T> values) {
  final camel = value.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
  return values.byName(camel);
}
