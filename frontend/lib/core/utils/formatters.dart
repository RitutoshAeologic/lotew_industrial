/// Human-readable formatting utilities for Industrial Telemetry and Forensics.
class AppFormatters {
  /// Smart Top 1-2 Units for clean, non-overflowing UI displays (Tables, Metric Cards, Badges).
  ///
  /// Examples:
  /// - ms (< 1s): '394.1 ms'
  /// - s (< 60s): '45.0 s'
  /// - min (< 60m): '1 min 35 s' or '15 min'
  /// - hrs (< 24h): '2 hrs 16 min' or '5 hrs'
  /// - days (< 30d): '4 days 6 hrs' or '12 days'
  /// - months (< 12mo): '3 mos 12 days' or '7 mos'
  /// - years (>= 1yr): '23 yrs 3 mos' or '2 yrs'
  static String formatDurationMs(double? ms) {
    if (ms == null) return 'N/A';
    if (ms == 0.0) return '0 ms (Synchronous)';
    if (ms < 0) return '0 ms';

    if (ms < 1000) {
      return '${ms.toStringAsFixed(1)} ms';
    }

    final totalMs = ms.round();
    final totalSeconds = totalMs ~/ 1000;
    if (totalSeconds < 60) {
      return '${(ms / 1000.0).toStringAsFixed(1)} s';
    }

    final totalMinutes = totalSeconds ~/ 60;
    final remSec = totalSeconds % 60;
    if (totalMinutes < 60) {
      return remSec > 0 ? '$totalMinutes min $remSec s' : '$totalMinutes min';
    }

    final totalHours = totalMinutes ~/ 60;
    final remMin = totalMinutes % 60;
    if (totalHours < 24) {
      return remMin > 0 ? '$totalHours hrs $remMin min' : '$totalHours hrs';
    }

    final totalDays = totalHours ~/ 24;
    final remHours = totalHours % 24;
    if (totalDays < 30) {
      return remHours > 0 ? '$totalDays days $remHours hrs' : '$totalDays days';
    }

    final years = totalDays ~/ 365;
    final remDaysAfterYears = totalDays % 365;
    final months = remDaysAfterYears ~/ 30;
    final remDays = remDaysAfterYears % 30;

    if (years > 0) {
      return months > 0 ? '$years yrs $months mos' : '$years yrs';
    }
    return remDays > 0 ? '$months mos $remDays days' : '$months mos';
  }

  /// Full exact breakdown across all granularities:
  /// "23 years 3 months 29 days 23 hours 59 minutes 30 seconds 982 ms"
  ///
  /// Ideal for audit logs, forensic modals, and hover tooltips.
  static String formatFullDetailedDuration(double? ms) {
    if (ms == null) return 'N/A';
    if (ms == 0.0) return '0 ms (Synchronous)';
    if (ms < 0) return '0 ms';

    final totalMs = ms.round();
    final remMs = totalMs % 1000;
    final totalSeconds = totalMs ~/ 1000;
    final remSec = totalSeconds % 60;
    final totalMinutes = totalSeconds ~/ 60;
    final remMin = totalMinutes % 60;
    final totalHours = totalMinutes ~/ 60;
    final remHours = totalHours % 24;
    final totalDays = totalHours ~/ 24;
    final years = totalDays ~/ 365;
    final remDaysAfterYears = totalDays % 365;
    final months = remDaysAfterYears ~/ 30;
    final remDays = remDaysAfterYears % 30;

    final List<String> parts = [];
    if (years > 0) parts.add('$years ${years == 1 ? "year" : "years"}');
    if (months > 0) parts.add('$months ${months == 1 ? "month" : "months"}');
    if (remDays > 0) parts.add('$remDays ${remDays == 1 ? "day" : "days"}');
    if (remHours > 0) parts.add('$remHours ${remHours == 1 ? "hour" : "hours"}');
    if (remMin > 0) parts.add('$remMin ${remMin == 1 ? "minute" : "minutes"}');
    if (remSec > 0) parts.add('$remSec ${remSec == 1 ? "second" : "seconds"}');
    if (remMs > 0 || parts.isEmpty) parts.add('$remMs ms');

    return parts.join(' ');
  }

  /// Rich multi-line tooltip content combining full human breakdown + exact raw milliseconds.
  static String formatTooltipDuration(double? ms) {
    if (ms == null) return 'Not recorded';
    if (ms == 0.0) return '0 ms (Synchronous / Real-Time)';

    final fullBreakdown = formatFullDetailedDuration(ms);
    final rawFormatted = ms.toStringAsFixed(3);
    return '$fullBreakdown\n(Exact: $rawFormatted ms)';
  }

  /// Format byte counts into KB, MB, GB
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
