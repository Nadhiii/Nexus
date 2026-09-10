import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic Flutter test harness is operational', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Nexus'))),
    );

    expect(find.text('Nexus'), findsOneWidget);
  });
}
