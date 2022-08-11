import 'dart:io';

import 'package:test/test.dart';
import 'package:mime_type/mime_type.dart';

void main() {
  test('gets mime type of pdf ', () {
    final fp = File('/home/bett/Downloads/Douglas-CV.pdf');
    final type = mime(fp.path);
    // print(type);
    expect(type, 'application/pdf');
  });
}
