import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:test/test.dart';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

void main() {
  final port = '8080';
  final host = 'http://localhost:$port';
  late Process p;

  setUpAll(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port, 'IS_DEBUG': 'false'},
    );
    // Wait for server to start and print to stdout.
    await p.stdout.first;
  });

  tearDownAll(() => p.kill());

  test('Root', () async {
    final response = await get(Uri.parse('$host/'));
    expect(response.statusCode, 200);
    expect(response.body, 'Hello, World!\n');
  });

  test('Echo', () async {
    final response = await get(Uri.parse('$host/echo/hello'));
    expect(response.statusCode, 200);
    expect(response.body, 'hello\n');
  });

  test('404', () async {
    final response = await get(Uri.parse('$host/foobar'));
    expect(response.statusCode, 404);
  });
  group('files/file_upload', () {
    test('Can Upload a file', () async {
      final fp = File('README.md');
      final exists = await fp.exists();
      expect(exists, true);
      final uri = Uri.parse('$host/files/file_upload');
      var request = MultipartRequest('POST', uri)
        ..fields['user'] = 'nweiz@google.com'
        ..fields['file_name'] = fp.path
        ..files.add(
          await MultipartFile.fromPath(
            'filename',
            fp.path,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      var response = await request.send();
      expect(response.statusCode, 200);
      final url = await response.stream.bytesToString();
      expect(url, isNotNull);
    }, timeout: Timeout.none);

    test('Can Upload file via http', () async {
      // final filePath = kIsWeb ? null : file.path;
      // final mimeType = filePath != null ? lookupMimeType(filePath) : null;
      // final contentType = mimeType != null ? MediaType.parse(mimeType) : null;
      final fp = File('README.md');
      final bytes = await fp.readAsBytes();
      final url = '$host/files/file_upload';
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = http.MultipartFile.fromBytes(
        'filename',
        bytes,
        filename: 'filename',
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);

      final httpClient = http.Client();
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final body = await response.stream.transform(utf8.decoder).join();
      return body;
      // final uri = Uri.parse('$host/files/file_upload');
      // var request = http.MultipartRequest('POST', uri)
      //   ..fields['user'] = 'nweiz@google.com'
      //   ..fields['file_name'] = ''
      //   ..files.add(
      //      http.MultipartFile.fromBytes(
      //       'filename',
      //       file.bytes!,
      //       contentType: MediaType('application', 'pdf'),
      //     ),
      //   );
      // var response = await request.send();
      // final url = await response.stream.bytesToString();
      // return url;
    });
  });
  test('can download file', () async {
    final fp = File('README.md');

    final exists = await fp.exists();
    expect(exists, true);
    final uri = Uri.parse('$host/files/file_upload');
    var request = MultipartRequest('POST', uri)
      ..fields['user'] = 'nweiz@google.com'
      ..fields['file_name'] = fp.path
      ..files.add(
        await MultipartFile.fromPath(
          'filename',
          fp.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    var response = await request.send();
    expect(response.statusCode, 200);
    final url = await response.stream.bytesToString();
    final getFileUri = Uri.parse(
      '$host/files/$url',
    );
    final getFileResponse = await get(getFileUri);
    expect(getFileResponse.statusCode, equals(200));
  }, timeout: Timeout.none);
}
