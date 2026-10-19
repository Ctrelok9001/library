import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());

    expect(tester.takeException(), isNull);
  });
}