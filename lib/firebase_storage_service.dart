import 'dart:io';

import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final Storage storage;
  late Bucket bucket;
  FirebaseStorageService({
    required this.storage,
  }) {
    bucket = storage.bucket('innostrategies_net_bucket');
  }

  Future<String> uploadFile(File file, String fileName) async {
    // https://console.cloud.google.com/apis/dashboard storage needs to be enabled

    fileName = '${Uuid().v4()}-$fileName'.replaceAll(' ', '_');
    final response = await file.openRead().pipe(bucket.write(fileName));
    print(response);
    return fileName;
  }

  Future<File> getFile(String fileName) async {
    await Directory('images/downloaded/').create();
    final file = await File('images/downloaded/$fileName').create();
    await bucket.read(fileName).pipe(file.openWrite());
    return file;
  }
}

Future<Storage> initializeCloudStorage() async {
  /// download service account from console.firebase.google.com
  var jsonCredentials = File(
    'for-the-community-firebase-adminsdk-dtush-758d6ad2ba.json',
  ).readAsStringSync();
  var creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
  var scopes = [...Storage.SCOPES];
  var client = await auth.clientViaServiceAccount(creds, scopes);

  /// refer to the project id below
  return Storage(client, 'for-the-community');
}

// "b/innostrategies_net_bucket/o/0dfd7365-f7ca-49b6-a36c-61b2fcd209db-The_ONE_Thing_by_Gary_Keller_%28z-lib.org%29.epub"
