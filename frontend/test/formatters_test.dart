import 'package:flutter_test/flutter_test.dart';
import 'package:lotew_industrial_web/core/utils/formatters.dart';

void main() {
  group('AppFormatters.formatDurationMs tests (Smart Top-2 Units)', () {
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

    test('formats seconds (< 60 s)', () {
      expect(AppFormatters.formatDurationMs(1000.0), '1.0 s');
      expect(AppFormatters.formatDurationMs(45000.0), '45.0 s');
      expect(AppFormatters.formatDurationMs(59900.0), '59.9 s');
    });

    test('formats minutes with remainder seconds (< 60 min)', () {
      expect(AppFormatters.formatDurationMs(60 * 1000.0), '1 min');
      expect(AppFormatters.formatDurationMs((1 * 60 + 35) * 1000.0), '1 min 35 s');
      expect(AppFormatters.formatDurationMs((45 * 60 + 12) * 1000.0), '45 min 12 s');
    });

    test('formats hours with remainder minutes (< 24 hrs)', () {
      expect(AppFormatters.formatDurationMs(2 * 3600 * 1000.0), '2 hrs');
      expect(AppFormatters.formatDurationMs((2 * 3600 + 16 * 60) * 1000.0), '2 hrs 16 min');
    });

    test('formats days with remainder hours (< 30 days)', () {
      expect(AppFormatters.formatDurationMs(4 * 86400 * 1000.0), '4 days');
      expect(AppFormatters.formatDurationMs((4 * 86400 + 6 * 3600) * 1000.0), '4 days 6 hrs');
    });

    test('formats years with remainder months (>= 365 days)', () {
      expect(AppFormatters.formatDurationMs(365 * 86400 * 1000.0), '1 yrs');
      // 23 years and approx 3 months
      const double targetMs = (23 * 365 + 3 * 30 + 10) * 86400.0 * 1000.0;
      expect(AppFormatters.formatDurationMs(targetMs), '23 yrs 3 mos');
    });
  });

  group('AppFormatters.formatFullDetailedDuration tests (Full Breakdown)', () {
    test('handles small and single unit values', () {
      expect(AppFormatters.formatFullDetailedDuration(null), 'N/A');
      expect(AppFormatters.formatFullDetailedDuration(0.0), '0 ms (Synchronous)');
      expect(AppFormatters.formatFullDetailedDuration(394.0), '394 ms');
      expect(AppFormatters.formatFullDetailedDuration(95400.0), '1 minute 35 seconds 400 ms');
    });

    test('formats exact multi-unit breakdown like 23 years 3 months 29 days 23 hours 59 min 30 s 982 ms', () {
      // Calculate exact ms for:
      // 23 years (23 * 365 days)
      // 3 months (3 * 30 days)
      // 29 days
      // 23 hours
      // 59 minutes
      // 30 seconds
      // 982 ms
      const int totalDays = (23 * 365) + (3 * 30) + 29;
      const int totalHours = (totalDays * 24) + 23;
      const int totalMinutes = (totalHours * 60) + 59;
      const int totalSeconds = (totalMinutes * 60) + 30;
      const double exactMs = (totalSeconds * 1000.0) + 982.0;

      final result = AppFormatters.formatFullDetailedDuration(exactMs);
      expect(result, '23 years 3 months 29 days 23 hours 59 minutes 30 seconds 982 ms');
    });
  });

  group('AppFormatters.formatTooltipDuration tests', () {
    test('combines full breakdown with exact ms for tooltips', () {
      final tooltip = AppFormatters.formatTooltipDuration(394.085);
      expect(tooltip.contains('394 ms'), isTrue);
      expect(tooltip.contains('(Exact: 394.085 ms)'), isTrue);
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
