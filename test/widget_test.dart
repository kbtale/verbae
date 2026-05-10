// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_verb_master/main.dart';

void main() {
  testWidgets('renders the Verbae home screen', (tester) async {
    await tester.pumpWidget(const VerbaeApp());

    expect(find.text('Select a Language'), findsOneWidget);
    expect(find.text('View Progress'), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
  });
}
