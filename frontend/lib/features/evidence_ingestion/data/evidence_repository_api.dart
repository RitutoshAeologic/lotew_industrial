import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:lotew_industrial_web/core/network/api_endpoints.dart';
import 'package:lotew_industrial_web/core/network/dio_client.dart';
import 'package:lotew_industrial_web/features/evidence_ingestion/domain/models/evidence_item_model.dart';
import 'evidence_repository.dart';

/// Live FastAPI backend implementation using Dio HTTP client.
/// Communicates directly with the Lotew Industrial Backend engine.
class EvidenceRepositoryApi implements EvidenceRepository {
  final DioClient dioClient;

  EvidenceRepositoryApi({required this.dioClient});

  @override
  Future<EvidenceItemModel> ingestTelemetryCycle({
    required int cycleId,
    required String tenantId,
    required String assetId,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.ingestCycle,
      data: {
        'cycle_id': cycleId,
        'tenant_id': tenantId,
        'asset_id': assetId,
      },
    );
    return EvidenceItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<EvidenceItemModel> uploadCsv({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
    required String componentId,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'tenant_id': tenantId,
      'asset_id': assetId,
      'component_id': componentId,
    });
    final response = await dioClient.dio.post(
      ApiEndpoints.uploadCsv,
      data: formData,
    );
    return EvidenceItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> uploadRigZip({
    required Uint8List fileBytes,
    required String fileName,
    required String tenantId,
    required String assetId,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'tenant_id': tenantId,
      'asset_id': assetId,
    });
    final response = await dioClient.dio.post(
      ApiEndpoints.uploadRigZip,
      data: formData,
    );
    return response.data as Map<String, dynamic>;
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
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'tenant_id': tenantId,
      'asset_id': assetId,
      'component_id': componentId,
      'incident_date': incidentDate.toIso8601String(),
      'proposed_action': proposedAction,
      'notes': notes,
    });
    final response = await dioClient.dio.post(
      ApiEndpoints.uploadPdf,
      data: formData,
    );
    return EvidenceItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<EvidenceItemModel>> getEvidenceTimeline({
    required String tenantId,
    required String assetId,
  }) async {
    final response = await dioClient.dio.get(
      ApiEndpoints.timeline,
      queryParameters: {
        'tenant_id': tenantId,
        'asset_id': assetId,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((item) => EvidenceItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
