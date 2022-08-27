import 'package:path_provider/path_provider.dart';

// ignore: avoid_classes_with_only_static_members
class ExtStorageProvider {
  // getting external storage path
  static Future<String?> getExtStorage({required String dirName}) async {
    final directory = await getDownloadsDirectory();

    return directory!.path;
  }
}
