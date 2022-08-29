import 'dart:io';

import 'package:http/http.dart';
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:test/test.dart';

void main() {
  final port = '8080';
  final host = 'http://localhost:$port';
  // final host = 'https://unitech-file-server-gskgoc2hxq-ez.a.run.app';
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
