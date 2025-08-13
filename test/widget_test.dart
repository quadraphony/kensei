import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kensei_tunnel/main.dart';

void main() {
  testWidgets('Kensei Tunnel app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KenseiTunnelApp());

    // Verify that the app starts with the home screen
    expect(find.text('Kensei Tunnel'), findsOneWidget);
  });
}
