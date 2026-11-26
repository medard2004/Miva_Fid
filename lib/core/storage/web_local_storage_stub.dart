String? webStorageGet(String key) => null;

bool webStorageSet(String key, String value) => false;

void webStorageRemove(String key) {}

void webStorageRemoveByPrefix(
  String prefix, {
  Set<String> excludeKeys = const {},
}) {}
