import 'dart:io';

import 'package:firestore_proxy/firebase_storage_service.dart';
import 'package:gcloud/storage.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseStorageService', () {
    late Storage storage;
    late FirebaseStorageService storageService;

    setUpAll(() async {
      final path = Platform.environment['ADMIN_SDK_FILE_PATH'];
      if (path == null) {
        throw Exception('Missing ADMIN_SDK_FILE_PATH environment variable');
      }
      storage = await initializeCloudStorage(path);
      storageService = FirebaseStorageService(storage: storage);
    });

    test('can initialize storage service', () {
      expect(storage, isNotNull);
    });

    test('can upload a file returning the filename', () async {
      final fp = File('README.md');
      final result = await storageService.uploadFile(fp, 'README.md');
      expect(result, isNotNull);
    });

    test('can download a file given a filename', () async {
      final fp = File('README.md');
      final result = await storageService.uploadFile(fp, 'README.md');
      expect(result, isNotNull);
      final file = await storageService.getFile(result);
      expect(file, isNotNull);
    }, timeout: Timeout.none);

    test('can delete a file', () async {
      final fp = File('README.md');
      final result = await storageService.uploadFile(fp, 'README.md');
      expect(result, isNotNull);
      await storageService.deleteFile(result);
    });
  });
}
