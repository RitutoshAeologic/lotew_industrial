import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:lotew_industrial_web/features/evidence_ingestion/domain/models/evidence_item_model.dart';
import 'evidence_repository.dart';

/// Standalone offline mock repository implementation.
/// Simulates realistic SHA-256 cryptographic hashes, 3-timestamp millisecond latencies,
/// and physical sensor waveforms without requiring the FastAPI backend or Supabase.
class EvidenceRepositoryMock implements EvidenceRepository {
  final List<EvidenceItemModel> _memoryStore = [];
  bool _initialized = false;

  EvidenceRepositoryMock() {
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now().toUtc();
    final anchorEpoch = DateTime.parse('2024-01-01T00:00:00.000Z');

    // Default Telemetry Cycle #1 (Nominal baseline)
    final cycle1EventTime = anchorEpoch;
    final cycle1Sha = _calculateSha256(utf8.encode('PARQUET_ZSTD_CYCLE_0001_MOCK_PAYLOAD'));
    final cycle1 = EvidenceItemModel(
      id: 'mock-uuid-telemetry-0001',
      tenantId: 'hydraulic_lab',
      assetId: 'hydraulic_rig_01',
      componentId: 'system',
      evidenceType: 'TELEMETRY_CYCLE',
      cycleId: 1,
      rawFileName: 'cycle_0001.parquet',
      rawStoragePath: 'telemetry/hydraulic_lab/hydraulic_rig_01/cycle_0001.parquet',
      rawFileSha256: cycle1Sha,
      eventTime: cycle1EventTime,
      ingestionTime: now.subtract(const Duration(hours: 1)),
      availableTime: now.subtract(const Duration(hours: 1)).add(const Duration(milliseconds: 32)),
      ingestionLatencyMs: 45.2,
      processingLatencyMs: 32.1,
      qualityFlag: 'NOMINAL',
      canonicalData: _buildTelemetryCanonicalData(
        cycleId: 1,
        tenantId: 'hydraulic_lab',
        assetId: 'hydraulic_rig_01',
        rawSha: cycle1Sha,
        eventTime: cycle1EventTime,
        isDegraded: false,
      ),
    );

    // Default PDF Maintenance Document
    final pdfEventTime = now.subtract(const Duration(days: 2));
    final pdfSha = _calculateSha256(utf8.encode('PDF_INSPECTION_LOG_PUMP_SEAL_MOCK_PAYLOAD'));
    final pdfItem = EvidenceItemModel(
      id: 'mock-uuid-pdf-0001',
      tenantId: 'hydraulic_lab',
      assetId: 'hydraulic_rig_01',
      componentId: 'pump',
      evidenceType: 'PDF_DOCUMENT',
      cycleId: null,
      rawFileName: 'quarterly_hydraulic_inspection.pdf',
      rawStoragePath: 'documents/hydraulic_lab/hydraulic_rig_01/quarterly_hydraulic_inspection.pdf',
      rawFileSha256: pdfSha,
      eventTime: pdfEventTime,
      ingestionTime: now.subtract(const Duration(days: 2)).add(const Duration(minutes: 5)),
      availableTime: now.subtract(const Duration(days: 2)).add(const Duration(minutes: 5, milliseconds: 78)),
      ingestionLatencyMs: 300000.0,
      processingLatencyMs: 78.4,
      qualityFlag: 'NOMINAL',
      extractedText: 'QUARTERLY HYDRAULIC RIG MAINTENANCE REPORT\n'
          'Rig Identifier: hydraulic_rig_01\n'
          'Component Checked: Axial Piston Main Pump\n'
          'Findings: Nominal pressure maintenance at 156 bar. Slight thermal rise at cooler intake (TS1 = 45.2 C).\n'
          'Action Recommended: CONTINUE_NORMAL_OPERATION.',
      canonicalData: {
        'schema': {'name': 'lotew.canonical_observation', 'version': '1.0.0'},
        'tenant_id': 'hydraulic_lab',
        'source': {
          'type': 'PDF_DOCUMENT',
          'raw_file_name': 'quarterly_hydraulic_inspection.pdf',
          'sha256': pdfSha,
          'pages_count': 2,
        },
        'asset': {
          'tenant_id': 'hydraulic_lab',
          'asset_id': 'hydraulic_rig_01',
          'component_id': 'pump',
        },
        'timestamps': {
          'event_time': pdfEventTime.toIso8601String(),
          'ingestion_time': now.subtract(const Duration(days: 2)).toIso8601String(),
          'available_time': now.subtract(const Duration(days: 2)).add(const Duration(milliseconds: 78)).toIso8601String(),
          'processing_latency_ms': 78.4,
        },
        'measurements': {
          'document_metadata': {
            'proposed_action': 'CONTINUE_NORMAL_OPERATION',
            'component_id': 'pump',
            'notes': 'Quarterly preventative maintenance complete.',
          },
        },
      },
    );

    _memoryStore.add(cycle1);
    _memoryStore.add(pdfItem);
  }

  String _calculateSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> _buildTelemetryCanonicalData({
    required int cycleId,
    required String tenantId,
    required String assetId,
    required String rawSha,
    required DateTime eventTime,
    required bool isDegraded,
  }) {
    final now = DateTime.now().toUtc();
    final medianPressure = isDegraded ? 145.0 : 155.0;
    final medianFlow = isDegraded ? 17.5 : 19.2;

    final ps1Curve = List.generate(60, (i) {
      double factor;
      if (i < 15) {
        factor = 0.88 + (i / 15) * 0.12;
      } else if (i < 35) {
        factor = 1.0;
      } else if (i < 45) {
        factor = 0.92;
      } else {
        factor = 0.82;
      }
      return double.parse((medianPressure * factor + (sin(i * 0.3) * 0.8)).toStringAsFixed(2));
    });

    final fs1Curve = List.generate(60, (i) {
      double factor;
      if (i < 15) {
        factor = 0.50 + (i / 15) * 0.50;
      } else if (i < 35) {
        factor = 1.0;
      } else if (i < 45) {
        factor = 0.85;
      } else {
        factor = 0.35;
      }
      return double.parse((medianFlow * factor + (cos(i * 0.2) * 0.1)).toStringAsFixed(2));
    });

    return {
      'schema': {'name': 'lotew.canonical_observation', 'version': '1.0.0'},
      'tenant_id': tenantId,
      'source': {
        'type': 'TELEMETRY_CYCLE',
        'format': 'PARQUET',
        'cycle_id': cycleId,
        'raw_sha256': rawSha,
        'compression': 'zstd',
        'sensors_count': 17,
        'total_samples': 43680,
        'is_synthetic': true,
      },
      'asset': {
        'tenant_id': tenantId,
        'asset_id': assetId,
        'component_id': 'system',
      },
      'timestamps': {
        'event_time': eventTime.toIso8601String(),
        'ingestion_time': now.toIso8601String(),
        'available_time': now.add(const Duration(milliseconds: 38)).toIso8601String(),
        'ingestion_latency_ms': 12.5,
        'processing_latency_ms': 38.2,
      },
      'measurements': {
        'components': {
          'pump': {
            'PS1': {
              'median': medianPressure,
              'mad': 1.15,
              'min': isDegraded ? 101.4 : 142.1,
              'max': isDegraded ? 116.8 : 166.4,
              'rate_hz': 100,
              'unit': 'bar',
              'samples_count': 6000,
            },
            'FS1': {
              'median': medianFlow,
              'mad': 0.09,
              'min': isDegraded ? 1.7 : 7.1,
              'max': isDegraded ? 2.3 : 8.2,
              'rate_hz': 10,
              'unit': 'L/min',
              'samples_count': 600,
            },
          },
          'cooler': {
            'TS1': {
              'median': 45.1,
              'mad': 0.2,
              'min': 44.0,
              'max': 46.2,
              'rate_hz': 1,
              'unit': 'degC',
              'samples_count': 60,
            },
            'CE': {
              'median': 38.5,
              'mad': 0.4,
              'min': 37.0,
              'max': 40.0,
              'rate_hz': 1,
              'unit': '%',
              'samples_count': 60,
            },
          },
        },
        'waveform_downsampled_60s': {
          'time_sec': List.generate(60, (i) => i + 1),
          'PS1_pressure_bar': ps1Curve,
          'FS1_flow_lmin': fs1Curve,
        },
      },
      'metadata': {
        'cycle_id': cycleId,
        'cycle_duration_seconds': 60,
        'rig_specification': 'UCI Hydraulic Test Bench (ZeMA Simulator)',
      },
    };
  }

  @override
  Future<EvidenceItemModel> ingestTelemetryCycle({
    required int cycleId,
    required String tenantId,
    required String assetId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final isSevereLeak = (cycleId >= 211 && cycleId <= 220);
    final qualityFlag = isSevereLeak ? 'DEGRADED_LEAK' : 'NOMINAL';
    final now = DateTime.now().toUtc();
    final anchorEpoch = DateTime.parse('2024-01-01T00:00:00.000Z');
    final eventTime = anchorEpoch.add(Duration(seconds: (cycleId - 1) * 60));
    final rawFileName = 'cycle_${cycleId.toString().padLeft(4, "0")}.parquet';
    final pseudoBytes = utf8.encode('PARQUET_ZSTD_${cycleId}_${tenantId}_$assetId');
    final sha = _calculateSha256(pseudoBytes);

    final item = EvidenceItemModel(
      id: 'mock-telemetry-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      assetId: assetId,
      componentId: 'system',
      evidenceType: 'TELEMETRY_CYCLE',
      cycleId: cycleId,
      rawFileName: rawFileName,
      rawStoragePath: 'telemetry/$tenantId/$assetId/$rawFileName',
      rawFileSha256: sha,
      eventTime: eventTime,
      ingestionTime: now,
      availableTime: now.add(const Duration(milliseconds: 35)),
      ingestionLatencyMs: 14.8,
      processingLatencyMs: 35.4,
      qualityFlag: qualityFlag,
      canonicalData: _buildTelemetryCanonicalData(
        cycleId: cycleId,
        tenantId: tenantId,
        assetId: assetId,
        rawSha: sha,
        eventTime: eventTime,
        isDegraded: isSevereLeak,
      ),
    );

    _memoryStore.insert(0, item);
    return item;
  }

  @override
  Future<List<EvidenceItemModel>> ingestTelemetryRange({
    required int startCycle,
    required int endCycle,
    required String tenantId,
    required String assetId,
  }) async {
    final List<EvidenceItemModel> results = [];
    for (int c = startCycle; c <= endCycle; c++) {
      final item = await ingestTelemetryCycle(cycleId: c, tenantId: tenantId, assetId: assetId);
      results.add(item);
    }
    return results;
  }

  @override
  Future<EvidenceItemModel> uploadCsv({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
    required String componentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now().toUtc();
    final sha = _calculateSha256(fileBytes);

    final item = EvidenceItemModel(
      id: 'mock-csv-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      assetId: assetId,
      componentId: componentId,
      evidenceType: 'CSV_TELEMETRY',
      cycleId: null,
      rawFileName: fileName,
      rawStoragePath: 'telemetry_csv/$tenantId/$assetId/$fileName',
      rawFileSha256: sha,
      eventTime: now.subtract(const Duration(minutes: 5)),
      ingestionTime: now,
      availableTime: now.add(const Duration(milliseconds: 48)),
      ingestionLatencyMs: 25.0,
      processingLatencyMs: 48.2,
      qualityFlag: 'NOMINAL',
      canonicalData: {
        'schema': {'name': 'lotew.canonical_observation', 'version': '1.0.0'},
        'tenant_id': tenantId,
        'source': {
          'type': 'CSV_TELEMETRY',
          'format': 'PARQUET',
          'raw_sha256': sha,
          'compression': 'zstd',
          'component_id': componentId,
        },
        'asset': {
          'tenant_id': tenantId,
          'asset_id': assetId,
          'component_id': componentId,
        },
        'timestamps': {
          'event_time': now.subtract(const Duration(minutes: 5)).toIso8601String(),
          'ingestion_time': now.toIso8601String(),
          'available_time': now.add(const Duration(milliseconds: 48)).toIso8601String(),
          'processing_latency_ms': 48.2,
        },
        'measurements': {
          'components': {
            componentId: {
              'channel_1': {'median': 120.5, 'mad': 1.2, 'min': 118.0, 'max': 124.0, 'rate_hz': 10, 'unit': 'bar'},
            },
          },
        },
      },
    );

    _memoryStore.insert(0, item);
    return item;
  }

  @override
  Future<Map<String, dynamic>> uploadRigZip({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sha = _calculateSha256(fileBytes);

    return {
      'status': 'SUCCESS',
      'file_name': fileName,
      'sha256': sha,
      'storage_path': 'datasets/$tenantId/$assetId/${sha.substring(0, 16)}_$fileName',
      'extracted_count': 17,
      'sensor_files': [
        'PS1.txt', 'PS2.txt', 'PS3.txt', 'PS4.txt', 'PS5.txt', 'PS6.txt',
        'EPS1.txt', 'FS1.txt', 'FS2.txt', 'TS1.txt', 'TS2.txt', 'TS3.txt',
        'TS4.txt', 'CE.txt', 'CP.txt', 'SE.txt', 'VS1.txt'
      ],
      'message': 'Successfully extracted and mounted 17 sensor files to test rig (Mock Mode).',
    };
  }

  @override
  Future<EvidenceItemModel> uploadPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
    required String componentId,
    required DateTime incidentDate,
    required String proposedAction,
    required String notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now().toUtc();
    final sha = _calculateSha256(fileBytes);

    final item = EvidenceItemModel(
      id: 'mock-pdf-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      assetId: assetId,
      componentId: componentId,
      evidenceType: 'PDF_DOCUMENT',
      cycleId: null,
      rawFileName: fileName,
      rawStoragePath: 'documents/$tenantId/$assetId/$fileName',
      rawFileSha256: sha,
      eventTime: incidentDate,
      ingestionTime: now,
      availableTime: now.add(const Duration(milliseconds: 45)),
      ingestionLatencyMs: now.difference(incidentDate).inMilliseconds.toDouble().clamp(0.0, 1000000.0),
      processingLatencyMs: 45.0,
      qualityFlag: 'NOMINAL',
      extractedText: 'MOCK PDF EXTRACTION REPORT\n'
          'File: $fileName\n'
          'Component: $componentId\n'
          'Proposed Action: $proposedAction\n'
          'Notes: $notes\n'
          'Extracted via Lotew Document Ingestion Engine.',
      canonicalData: {
        'schema': {'name': 'lotew.canonical_observation', 'version': '1.0.0'},
        'tenant_id': tenantId,
        'source': {
          'type': 'PDF_DOCUMENT',
          'raw_file_name': fileName,
          'sha256': sha,
          'pages_count': 1,
        },
        'asset': {
          'tenant_id': tenantId,
          'asset_id': assetId,
          'component_id': componentId,
        },
        'timestamps': {
          'event_time': incidentDate.toIso8601String(),
          'ingestion_time': now.toIso8601String(),
          'available_time': now.add(const Duration(milliseconds: 45)).toIso8601String(),
          'processing_latency_ms': 45.0,
        },
        'measurements': {
          'document_metadata': {
            'proposed_action': proposedAction,
            'component_id': componentId,
            'notes': notes,
          },
        },
      },
    );

    _memoryStore.insert(0, item);
    return item;
  }

  @override
  Future<List<EvidenceItemModel>> getEvidenceTimeline({
    required String tenantId,
    required String assetId,
  }) async {
    // 150ms delay matching test expectation
    await Future.delayed(const Duration(milliseconds: 150));
    return List<EvidenceItemModel>.from(_memoryStore);
  }

  @override
  Future<void> clearTelemetry({
    required String tenantId,
    required String assetId,
  }) async {
    _memoryStore.removeWhere((item) => item.isTelemetry && item.tenantId == tenantId && item.assetId == assetId);
  }
}
