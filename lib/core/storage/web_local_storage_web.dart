import 'dart:js_interop';

@JS('window.localStorage')
external _LocalStorageJs? get _localStorage;

extension type _LocalStorageJs(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
  external int get length;
  external JSString? key(int index);
}

String? webStorageGet(String key) {
  try {
    return _localStorage?.getItem(key.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

void webStorageSet(String key, String value) {
  try {
    _localStorage?.setItem(key.toJS, value.toJS);
  } catch (_) {}
}

void webStorageRemove(String key) {
  try {
    _localStorage?.removeItem(key.toJS);
  } catch (_) {}
}

void webStorageRemoveByPrefix(String prefix) {
  try {
    final storage = _localStorage;
    if (storage == null) return;
    final keys = <String>[];
    final len = storage.length;
    for (var i = 0; i < len; i++) {
      final k = storage.key(i)?.toDart;
      if (k != null && k.startsWith(prefix)) {
        keys.add(k);
      }
    }
    for (final k in keys) {
      storage.removeItem(k.toJS);
    }
  } catch (_) {}
}
