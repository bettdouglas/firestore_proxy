import 'dart:io';

import 'package:firestore_proxy/firebase_storage_service.dart';
import 'package:gcloud/storage.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseStorageService', () {
    late Bucket bucket;
    late FirebaseStorageService storageService;

    setUpAll(() async {
      // final path = Platform.environment['ADMIN_SDK_FILE_PATH'];
      // if (path == null) {
      //   throw Exception('Missing ADMIN_SDK_FILE_PATH environment variable');
      // }
      final path = "for-the-community-firebase-adminsdk-dtush-758d6ad2ba.json";
      bucket = await initializeCloudStorageBucket(
        jsonCredentialsPath: path,
        bucketName: 'BUCKET_NAME',
        project: 'PROJECT',
      );
      storageService = FirebaseStorageService(bucket: bucket);
    });

    test('can initialize storage service', () {
      expect(bucket, isNotNull);
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
