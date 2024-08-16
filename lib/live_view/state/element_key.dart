/// A class representing a unique key for an element.
/// This key is used for identification and comparison purposes.
class ElementKey {
  final String key;

  ElementKey(this.key);

  @override
  bool operator ==(Object other) {
    return other is ElementKey && key == other.key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ElementKey{key: $key}';
}
