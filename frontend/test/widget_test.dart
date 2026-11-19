import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotew_industrial_web/app.dart';
import 'package:lotew_industrial_web/features/evidence_ingestion/presentation/screens/evidence_console_screen.dart';
import 'package:lotew_industrial_web/features/evidence_ingestion/presentation/widgets/zip_upload_card.dart';

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

  testWidgets('Approach B ZIP import toggle test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LotewIndustrialApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify initially in Simulator mode
    expect(find.text('Cycle Simulator (60s Stream)'), findsOneWidget);
    expect(find.text('Import Raw 17-Sensor ZIP'), findsOneWidget);
    expect(find.text('PHYSICAL 60-SECOND STREAMING'), findsOneWidget);

    // Switch to Raw ZIP Import mode
    await tester.tap(find.text('Import Raw 17-Sensor ZIP'));
    await tester.pumpAndSettle();

    // Verify ZipUploadCard is displayed with Approach B callout & manifest
    expect(find.byType(ZipUploadCard), findsOneWidget);
    expect(find.text('Approach B: Direct HTTP Streaming (Zero Browser Parsing)'), findsOneWidget);
    expect(find.text('EXPECTED 17-SENSOR ARCHIVE MANIFEST'), findsOneWidget);
    expect(find.text('Browse ZIP Archive'), findsOneWidget);

    // Switch back to Cycle Simulator mode
    await tester.tap(find.text('Cycle Simulator (60s Stream)'));
    await tester.pumpAndSettle();

    // Verify back to simulator
    expect(find.byType(ZipUploadCard), findsNothing);
    expect(find.text('PHYSICAL 60-SECOND STREAMING'), findsOneWidget);
  });
}
