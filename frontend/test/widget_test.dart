import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotew_industrial_web/app.dart';
import 'package:lotew_industrial_web/features/evidence_ingestion/presentation/screens/evidence_console_screen.dart';

void main() {
  testWidgets('LotewIndustrialApp desktop smoke & mount test', (WidgetTester tester) async {
    // Set realistic Web viewport
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LotewIndustrialApp());
    // Advance time past any initial async data load timers (150ms in Mock repo)
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(LotewIndustrialApp), findsOneWidget);
    expect(find.byType(EvidenceConsoleScreen), findsOneWidget);
    expect(find.text('Industrial Evidence Ingestion Console'), findsOneWidget);
  });
}
