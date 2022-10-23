import 'dart:io';

import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final Bucket bucket;
  FirebaseStorageService({
    required this.bucket,
  });

  Future<String> uploadFile(File file, String fileName) async {
    // https://console.cloud.google.com/apis/dashboard storage needs to be enabled

    fileName = '${Uuid().v4()}-$fileName'.replaceAll(' ', '_');
    await file.openRead().pipe(bucket.write(fileName));
    return fileName;
  }

  Future<File> getFile(String fileName) async {
    await Directory('images/downloaded/').create();
    final file = await File('images/downloaded/$fileName').create();
    await bucket.read(fileName).pipe(file.openWrite());
    return file;
  }

  Future<void> deleteFile(String fileName) async {
    return bucket.delete(fileName);
  }
}

Future<Bucket> initializeCloudStorageBucket({
  required String jsonCredentialsPath,
  required String project,
  required String bucketName,
}) async {
  /// download service account from console.firebase.google.com
  var jsonCredentials = File(jsonCredentialsPath).readAsStringSync();
  var creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
  var scopes = [...Storage.SCOPES];
  var client = await auth.clientViaServiceAccount(creds, scopes);

  /// refer to the project id below
  return Storage(client, project).bucket(bucketName);
}

// "b/innostrategies_net_bucket/o/0dfd7365-f7ca-49b6-a36c-61b2fcd209db-The_ONE_Thing_by_Gary_Keller_%28z-lib.org%29.epub"
