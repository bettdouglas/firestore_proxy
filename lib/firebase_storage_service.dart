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
    final filename = '${Uuid().v4()}-$fileName';
    await file.openRead().pipe(bucket.write(filename));
    return filename;
  }

  Future<File> getFile(String fileName) async {
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
