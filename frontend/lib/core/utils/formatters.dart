/// Human-readable formatting utilities for Industrial Telemetry and Forensics.
class AppFormatters {
  /// Converts milliseconds into intuitive engineering scale:
  /// ms (<1s) -> s (<60s) -> min (<60m) -> hrs (<24h) -> days (<365d) -> yrs (>=365d)
  static String formatDurationMs(double? ms) {
    if (ms == null) return 'N/A';
    if (ms == 0.0) return '0 ms (Synchronous)';
    if (ms < 0) return '0 ms';

    // Less than 1 second (Milliseconds)
    if (ms < 1000) {
      return '${ms.toStringAsFixed(1)} ms';
    }

    final seconds = ms / 1000.0;
    // Less than 60 seconds
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)} s';
    }

    final minutes = seconds / 60.0;
    // Less than 60 minutes
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(1)} min';
    }

    final hours = minutes / 60.0;
    // Less than 24 hours
    if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    }

    final days = hours / 24.0;
    // Less than 365 days
    if (days < 365) {
      return '${days.toStringAsFixed(1)} days';
    }

    final years = days / 365.25;
    return '${years.toStringAsFixed(1)} yrs';
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
