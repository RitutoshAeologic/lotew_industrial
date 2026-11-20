import 'dart:typed_data';
import 'package:lotew_industrial_web/features/evidence_ingestion/domain/models/evidence_item_model.dart';

/// Abstract repository contract for industrial evidence ingestion.
/// Supports both live backend communication (FastAPI via DioClient)
/// and standalone offline mock mode for testing and demonstrations.
abstract class EvidenceRepository {
  /// Ingests a multi-sensor telemetry cycle from the test rig.
  Future<EvidenceItemModel> ingestTelemetryCycle({
    required int cycleId,
    required String tenantId,
    required String assetId,
  });

  /// Ingests a range of multi-sensor telemetry cycles from the test rig.
  Future<List<EvidenceItemModel>> ingestTelemetryRange({
    required int startCycle,
    required int endCycle,
    required String tenantId,
    required String assetId,
  });

  /// Ingests continuous multi-sensor CSV telemetry.
  Future<EvidenceItemModel> uploadCsv({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
    required String componentId,
  });

  /// Uploads and mounts a 17-sensor raw test bench ZIP package.
  Future<Map<String, dynamic>> uploadRigZip({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
  });

  /// Ingests a PDF documentary maintenance report or invoice.
  Future<EvidenceItemModel> uploadPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
    required String componentId,
    required DateTime incidentDate,
    required String proposedAction,
    required String notes,
  });

  /// Fetches the interleaved chronological evidence timeline.
  Future<List<EvidenceItemModel>> getEvidenceTimeline({
    required String tenantId,
    required String assetId,
  });

  /// Deletes all telemetry cycles for the specified tenant & asset from Supabase and memory.
  Future<void> clearTelemetry({
    required String tenantId,
    required String assetId,
  });
}
