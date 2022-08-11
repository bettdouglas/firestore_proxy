import 'dart:io';

import 'package:firestore_proxy/firebase_storage_service.dart';
import 'package:gcloud/storage.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseStorageService', () {
    late Storage storage;
    late FirebaseStorageService storageService;

    setUpAll(() async {
      storage = await initializeCloudStorage();
      storageService = FirebaseStorageService(storage: storage);
    });

    test('can initialize storage service', () {
      expect(storage, isNotNull);
    });

    test('can upload a file returning the filename', () async {
      final fp = File('/home/bett/Downloads/Douglas-CV.pdf');
      final result = await storageService.uploadFile(fp, 'DouglasCV.pdf');
      expect(result, isNotNull);
    });

    test('can download a file given a filename', () async {
      final fp = File('/home/bett/Downloads/Douglas-CV.pdf');
      final result = await storageService.uploadFile(fp, 'DouglasCV.pdf');
      expect(result, isNotNull);
      final file = await storageService.getFile(result);
      expect(file, isNotNull);
    });
  });
}
