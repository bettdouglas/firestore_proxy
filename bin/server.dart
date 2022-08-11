import 'dart:io';

import 'package:firestore_proxy/firebase_storage_service.dart';
import 'package:shelf_multipart/multipart.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
// Configure routes.

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

late FirebaseStorageService storageService;
Future<Response> _fileUploadHandler(Request request) async {
  if (!request.isMultipart) {
    return Response(401, body: 'not a multipart request');
  }
  final data = <String, Multipart>{
    await for (final formData in request.multipartFormData)
      formData.name: formData.part,
  };
  final fileName = await data['file_name']!.readString();
  final path = p.basename(fileName);

  final filePart = data['filename']!;
  final bytes = await filePart.readBytes();
  final uid = Uuid().v4();
  final file = await File('images/$uid-$path').writeAsBytes(bytes);
  final url = await storageService.uploadFile(file, path);
  return Response(HttpStatus.ok, body: url);
}

void main(List<String> args) async {
  final storage = await initializeCloudStorage();
  storageService = FirebaseStorageService(storage: storage);

  final router = Router().plus
    ..get('/', _rootHandler)
    ..get('/echo/<message>', _echoHandler)
    ..post('/files/file_upload', _fileUploadHandler)
    ..get('/files/<url>', (Request r, String url) async {
      final result = await storageService.getFile(url);
      return result;
    });

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);
  await shelfRun(
    () => handler,
    defaultBindAddress: ip,
    defaultBindPort: port,
  );

  print('Server listening on port $port');
}


// https://firebasestorage.googleapis.com/v0/b/for-the-community.appspot.com/o/images%2F58f24163-96c7-4708-99bc-3fa75b32d9672022-01-29%2010%3A17%3A54.493324.jpg?alt=media&token=e9bf9db5-1b0a-4c65-bd80-49fd9cf405df,https://firebasestorage.googleapis.com/v0/b/for-the-community.appspot.com/o/images%2Fbc911d9f-8e7b-49b3-9d81-5bf62eba46a02022-01-29%2010%3A17%3A57.579056.jpg?alt=media&token=8036b92f-5ec2-4639-aa64-a631ed161d31