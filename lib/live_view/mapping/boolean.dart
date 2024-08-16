/// Converts a string property to a boolean value.
bool? getBoolean(String? prop) {
  return switch (prop) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
