import 'dart:io';

import 'package:hive/hive.dart';
import 'package:musify/services/ext_storage.dart';

void addOrUpdateData(
  String category,
  dynamic key,
  dynamic value,
) {
  if (!Hive.isBoxOpen(category)) {
    Hive.openBox(category);
  }
  Hive.box(category).put(key, value);
}

Future getData(String category, dynamic key) async {
  if (!Hive.isBoxOpen(category)) {
    await Hive.openBox(category);
  }
  return Hive.box(category).get(key);
}

void deleteData(String category, dynamic key) {
  if (!Hive.isBoxOpen(category)) {
    Hive.openBox(category);
  }
  Hive.box(category).delete(key);
}

void clearCache() async {
  if (!Hive.isBoxOpen('cache')) {
    await Hive.openBox('cache');
  }
  await Hive.box('cache').clear();
}

Future backupData() async {
  final boxNames = ['user', 'settings'];
  final dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Musify/Data');

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);

    await File(Hive.box(boxNames[i]).path!)
        .copy('$dlPath/${boxNames[i]}Data.hive');
  }
  return 'Backuped Successfully!';
}

Future restoreData() async {
  final boxNames = ['user', 'settings'];
  final uplPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify/Data');

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);

    final box = await Hive.openBox(boxNames[i]);
    final boxPath = box.path;
    await File('${uplPath!}/${boxNames[i]}Data.hive').copy(boxPath!);
  }

  return 'Restored Successfully!';
}
