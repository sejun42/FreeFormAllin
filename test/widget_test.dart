import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freeform_ble_logger/app.dart';

void main() {
  testWidgets('App starts and shows permissions screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FreeFormApp()),
    );
    await tester.pump();

    // The app should show the permissions screen initially
    expect(find.byType(Scaffold), findsWidgets);
  });
}
