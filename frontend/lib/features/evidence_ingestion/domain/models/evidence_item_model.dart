class EvidenceItemModel {
  final String id;
  final String tenantId;
  final String assetId;
  final String? componentId;
  final String evidenceType; // 'PDF_DOCUMENT' | 'TELEMETRY_CYCLE'
  final int? cycleId;
  final String rawFileName;
  final String rawStoragePath;
  final String rawFileSha256;
  final DateTime? eventTime;
  final DateTime ingestionTime;
  final DateTime availableTime;
  final double? ingestionLatencyMs;
  final double? processingLatencyMs;
  final String qualityFlag;
  final String? extractedText;
  final Map<String, dynamic> canonicalData;

  const EvidenceItemModel({
    required this.id,
    required this.tenantId,
    required this.assetId,
    this.componentId,
    required this.evidenceType,
    this.cycleId,
    required this.rawFileName,
    required this.rawStoragePath,
    required this.rawFileSha256,
    this.eventTime,
    required this.ingestionTime,
    required this.availableTime,
    this.ingestionLatencyMs,
    this.processingLatencyMs,
    required this.qualityFlag,
    this.extractedText,
    required this.canonicalData,
  });

  bool get isPdf => evidenceType == 'PDF_DOCUMENT';
  bool get isTelemetry => evidenceType == 'TELEMETRY_CYCLE';

  factory EvidenceItemModel.fromJson(Map<String, dynamic> json) {
    return EvidenceItemModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? 'hydraulic_lab',
      assetId: json['asset_id']?.toString() ?? 'hydraulic_rig_01',
      componentId: json['component_id']?.toString(),
      evidenceType: json['evidence_type']?.toString() ?? 'PDF_DOCUMENT',
      cycleId: (json['cycle_id'] as num?)?.toInt(),
      rawFileName: json['raw_file_name']?.toString() ?? '',
      rawStoragePath: json['raw_storage_path']?.toString() ?? '',
      rawFileSha256: json['raw_file_sha256']?.toString() ?? '',
      eventTime: json['event_time'] != null ? DateTime.tryParse(json['event_time'].toString()) : null,
      ingestionTime: DateTime.tryParse(json['ingestion_time']?.toString() ?? '') ?? DateTime.now(),
      availableTime: DateTime.tryParse(json['available_time']?.toString() ?? '') ?? DateTime.now(),
      ingestionLatencyMs: (json['ingestion_latency_ms'] as num?)?.toDouble(),
      processingLatencyMs: (json['processing_latency_ms'] as num?)?.toDouble(),
      qualityFlag: json['quality_flag']?.toString() ?? 'NOMINAL',
      extractedText: json['extracted_text']?.toString(),
      canonicalData: json['canonical_data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'asset_id': assetId,
        'component_id': componentId,
        'evidence_type': evidenceType,
        'cycle_id': cycleId,
        'raw_file_name': rawFileName,
        'raw_storage_path': rawStoragePath,
        'raw_file_sha256': rawFileSha256,
        'event_time': eventTime?.toIso8601String(),
        'ingestion_time': ingestionTime.toIso8601String(),
        'available_time': availableTime.toIso8601String(),
        'ingestion_latency_ms': ingestionLatencyMs,
        'processing_latency_ms': processingLatencyMs,
        'quality_flag': qualityFlag,
        'extracted_text': extractedText,
        'canonical_data': canonicalData,
      };
}

