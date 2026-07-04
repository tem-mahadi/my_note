// Basic smoke test for the My Notes app.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_note/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyNoteApp());
  });
}
