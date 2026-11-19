import 'package:flutter_test/flutter_test.dart';
import 'package:lotew_industrial_web/core/utils/formatters.dart';

void main() {
  group('AppFormatters.formatDurationMs tests', () {
    test('handles null, zero and negative values', () {
      expect(AppFormatters.formatDurationMs(null), 'N/A');
      expect(AppFormatters.formatDurationMs(0.0), '0 ms (Synchronous)');
      expect(AppFormatters.formatDurationMs(-5.0), '0 ms');
    });

    test('formats milliseconds (< 1000 ms)', () {
      expect(AppFormatters.formatDurationMs(45.2), '45.2 ms');
      expect(AppFormatters.formatDurationMs(394.085), '394.1 ms');
      expect(AppFormatters.formatDurationMs(999.0), '999.0 ms');
    });

    test('formats seconds (1000 ms <= t < 60 s)', () {
      expect(AppFormatters.formatDurationMs(1000.0), '1.0 s');
      expect(AppFormatters.formatDurationMs(45000.0), '45.0 s');
      expect(AppFormatters.formatDurationMs(59900.0), '59.9 s');
    });

    test('formats minutes (60 s <= t < 60 min)', () {
      expect(AppFormatters.formatDurationMs(60 * 1000.0), '1.0 min');
      expect(AppFormatters.formatDurationMs(15 * 60 * 1000.0), '15.0 min');
      expect(AppFormatters.formatDurationMs(59 * 60 * 1000.0), '59.0 min');
    });

    test('formats hours (60 min <= t < 24 hrs)', () {
      expect(AppFormatters.formatDurationMs(60 * 60 * 1000.0), '1.0 hrs');
      expect(AppFormatters.formatDurationMs(4.5 * 60 * 60 * 1000.0), '4.5 hrs');
      expect(AppFormatters.formatDurationMs(23 * 60 * 60 * 1000.0), '23.0 hrs');
    });

    test('formats days (24 hrs <= t < 365 days)', () {
      expect(AppFormatters.formatDurationMs(24 * 60 * 60 * 1000.0), '1.0 days');
      expect(AppFormatters.formatDurationMs(120 * 24 * 60 * 60 * 1000.0), '120.0 days');
    });

    test('formats years (>= 365 days)', () {
      expect(AppFormatters.formatDurationMs(365.25 * 24 * 60 * 60 * 1000.0), '1.0 yrs');
      expect(AppFormatters.formatDurationMs(2 * 365.25 * 24 * 60 * 60 * 1000.0), '2.0 yrs');
    });
  });

  group('AppFormatters.formatBytes tests', () {
    test('formats bytes, KB, MB, GB', () {
      expect(AppFormatters.formatBytes(512), '512 B');
      expect(AppFormatters.formatBytes(2048), '2.0 KB');
      expect(AppFormatters.formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(AppFormatters.formatBytes(2 * 1024 * 1024 * 1024), '2.00 GB');
    });
  });
}
