class CanonicalObservationModel {
  final String schemaName;
  final String schemaVersion;
  final String tenantId;
  final Map<String, dynamic> source;
  final Map<String, dynamic> asset;
  final TimestampsBlockModel timestamps;
  final Map<String, dynamic> measurements;
  final Map<String, dynamic>? metadata;

  const CanonicalObservationModel({
    required this.schemaName,
    required this.schemaVersion,
    required this.tenantId,
    required this.source,
    required this.asset,
    required this.timestamps,
    required this.measurements,
    this.metadata,
  });

  factory CanonicalObservationModel.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] as Map<String, dynamic>? ?? {};
    return CanonicalObservationModel(
      schemaName: schema['name']?.toString() ?? 'lotew.canonical_observation',
      schemaVersion: schema['version']?.toString() ?? '1.0.0',
      tenantId: json['tenant_id']?.toString() ?? 'hydraulic_lab',
      source: json['source'] as Map<String, dynamic>? ?? {},
      asset: json['asset'] as Map<String, dynamic>? ?? {},
      timestamps: TimestampsBlockModel.fromJson(json['timestamps'] as Map<String, dynamic>? ?? {}),
      measurements: json['measurements'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema': {'name': schemaName, 'version': schemaVersion},
        'tenant_id': tenantId,
        'source': source,
        'asset': asset,
        'timestamps': timestamps.toJson(),
        'measurements': measurements,
        if (metadata != null) 'metadata': metadata,
      };
}

class TimestampsBlockModel {
  final DateTime? eventTime;
  final DateTime ingestionTime;
  final DateTime availableTime;
  final double? ingestionLatencyMs;
  final double? processingLatencyMs;

  const TimestampsBlockModel({
    this.eventTime,
    required this.ingestionTime,
    required this.availableTime,
    this.ingestionLatencyMs,
    this.processingLatencyMs,
  });

  factory TimestampsBlockModel.fromJson(Map<String, dynamic> json) {
    return TimestampsBlockModel(
      eventTime: json['event_time'] != null ? DateTime.tryParse(json['event_time'].toString()) : null,
      ingestionTime: DateTime.tryParse(json['ingestion_time']?.toString() ?? '') ?? DateTime.now(),
      availableTime: DateTime.tryParse(json['available_time']?.toString() ?? '') ?? DateTime.now(),
      ingestionLatencyMs: (json['ingestion_latency_ms'] as num?)?.toDouble(),
      processingLatencyMs: (json['processing_latency_ms'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'event_time': eventTime?.toIso8601String(),
        'ingestion_time': ingestionTime.toIso8601String(),
        'available_time': availableTime.toIso8601String(),
        if (ingestionLatencyMs != null) 'ingestion_latency_ms': ingestionLatencyMs,
        if (processingLatencyMs != null) 'processing_latency_ms': processingLatencyMs,
      };
}

