import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

File? _cachedFile;

Future<File> _file() async {
  if (_cachedFile != null) return _cachedFile!;
  final dir = await getApplicationDocumentsDirectory();
  _cachedFile = File('${dir.path}/settings.json');
  return _cachedFile!;
}

Future<Map<String, dynamic>> readFileStore() async {
  try {
    final file = await _file();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.trim().isEmpty) return {};
    return jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[settings_file_io] Erreur lecture préférences: $e');
    return {};
  }
}

Future<void> writeFileStore(Map<String, dynamic> data) async {
  try {
    final file = await _file();
    await file.writeAsString(jsonEncode(data));
  } catch (e) {
    debugPrint('[settings_file_io] Erreur écriture préférences: $e');
  }
}

