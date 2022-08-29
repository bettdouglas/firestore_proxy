import 'dart:io';

import 'package:firestore_proxy/firebase_storage_service.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
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
  await Directory('images').create();
  final file = await File('images/$uid-$path').writeAsBytes(bytes);
  // uploads to cloud storage
  final url = await storageService.uploadFile(file, path);
  return Response(HttpStatus.ok, body: url);
}

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final serviceAccountFp = Platform.environment['ADMIN_SDK_FILE_PATH'];

  if (serviceAccountFp == null) {
    throw Exception('Missing ADMIN_SDK_FILE_PATH environment variable');
  }

  final storage = await initializeCloudStorage(serviceAccountFp);
  storageService = FirebaseStorageService(storage: storage);

  final listChecker = originOneOf(['https://for-the-community.web.app']);

  final router = Router().plus
    ..get('/', _rootHandler)
    ..get('/echo/<message>', _echoHandler)
    ..post('/files/file_upload', _fileUploadHandler)
    ..get('/files/<url>', (Request r, String url) async {
      final result = await storageService.getFile(url);
      return result;
    })
    ..delete('/files/<url>', (Request r, String url) async {
      await storageService.deleteFile(url);
      return Response.ok('File successfully deleted');
    });

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  // For running in containers, we respect the PORT environment variable.

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(originChecker: listChecker))
      .addHandler(router);

  // if (isDebug) {
  // await shelfRun(
  //   () => handler,
  //   defaultBindAddress: ip,
  //   defaultBindPort: port,
  // );
  // } else {
  await serve(handler, ip, port);
  // }
  print('Server listening on port $port');
}
