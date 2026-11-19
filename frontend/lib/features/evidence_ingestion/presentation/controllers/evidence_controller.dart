import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/evidence_repository.dart';
import '../../data/evidence_repository_api.dart';
import '../../data/evidence_repository_mock.dart';
import '../../domain/models/evidence_item_model.dart';

class EvidenceController extends GetxController {
  static EvidenceController get to => Get.find();

  // Repository instances
  late final EvidenceRepository _apiRepo;
  late final EvidenceRepository _mockRepo;
  final isMockMode = false.obs;

  EvidenceRepository get _activeRepo => isMockMode.value ? _mockRepo : _apiRepo;

  // Active view tab: 0 = PDF Upload, 1 = Telemetry Simulator
  final activeTab = 0.obs;

  // Form State
  final selectedTenant = AppConstants.defaultTenantId.obs;
  final selectedAsset = AppConstants.defaultAssetId.obs;
  final selectedComponent = 'pump'.obs;
  final selectedAction = AppConstants.proposedActions.first.obs;
  final incidentDate = Rx<DateTime>(DateTime.now());
  final notesController = TextEditingController();

  // File Picker State
  final pickedPdfBytes = Rxn<Uint8List>();
  final pickedPdfName = RxnString();
  final pickedPdfSizeBytes = 0.obs;

  // Telemetry Simulator State
  final cycleId = 1.obs; // 1 to 2,205
  final isSevereLeakPreset = false.obs;

  // Loading & Ingestion State
  final isUploading = false.obs;
  final errorMessage = RxnString();
  final latestEvidence = Rxn<EvidenceItemModel>();
  final evidenceHistory = <EvidenceItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final dioClient = Get.find<DioClient>();
    _apiRepo = EvidenceRepositoryApi(dioClient: dioClient);
    _mockRepo = EvidenceRepositoryMock();

    // Load initial timeline / mock history
    loadTimeline();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  void switchTab(int index) {
    activeTab.value = index;
    errorMessage.value = null;
  }

  void toggleMockMode() {
    isMockMode.value = !isMockMode.value;
    loadTimeline();
    Get.snackbar(
      isMockMode.value ? 'Switched to Standalone Mock Mode' : 'Switched to Live Backend API',
      isMockMode.value
          ? 'Operating in offline demo mode. Real SHA-256 and ms latencies are simulated.'
          : 'Connecting to http://localhost:8000.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          pickedPdfBytes.value = file.bytes;
          pickedPdfName.value = file.name;
          pickedPdfSizeBytes.value = file.size;
          errorMessage.value = null;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to select PDF: $e';
    }
  }

  void clearSelectedPdf() {
    pickedPdfBytes.value = null;
    pickedPdfName.value = null;
    pickedPdfSizeBytes.value = 0;
  }

  Future<void> uploadPdf() async {
    if (pickedPdfBytes.value == null || pickedPdfName.value == null) {
      errorMessage.value = 'Please select a PDF file first.';
      return;
    }

    try {
      isUploading.value = true;
      errorMessage.value = null;

      final evidence = await _activeRepo.uploadPdf(
        fileBytes: pickedPdfBytes.value!,
        fileName: pickedPdfName.value!,
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
        componentId: selectedComponent.value,
        incidentDate: incidentDate.value,
        proposedAction: selectedAction.value,
        notes: notesController.text.trim(),
      );

      latestEvidence.value = evidence;
      evidenceHistory.insert(0, evidence);
      clearSelectedPdf();
      notesController.clear();

      Get.snackbar(
        'Documentary Evidence Ingested',
        'SHA-256: ${evidence.rawFileSha256.substring(0, 16)}... committed to memory in ${evidence.processingLatencyMs?.toStringAsFixed(1) ?? "35"} ms',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      // If live API failed and we are not in mock mode, offer to switch
      if (!isMockMode.value) {
        Get.snackbar(
          'Live Ingestion Error',
          'Could not reach backend API at localhost:8000. Switch to Mock Mode at top-right to test UI standalone.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      isUploading.value = false;
    }
  }

  void setCyclePreset(int targetCycle, {bool isSevereLeak = false}) {
    cycleId.value = targetCycle;
    isSevereLeakPreset.value = isSevereLeak;
  }

  Future<void> ingestTelemetryCycle() async {
    try {
      isUploading.value = true;
      errorMessage.value = null;

      final evidence = await _activeRepo.ingestTelemetryCycle(
        cycleId: cycleId.value,
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );

      latestEvidence.value = evidence;
      evidenceHistory.insert(0, evidence);

      Get.snackbar(
        'Telemetry Cycle ${cycleId.value} Ingested',
        'Parquet compressed and registered with SHA-256: ${evidence.rawFileSha256.substring(0, 16)}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C2FF),
        colorText: const Color(0xFF0F172A),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> loadTimeline() async {
    try {
      final items = await _activeRepo.getEvidenceTimeline(
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );
      evidenceHistory.assignAll(items);
      if (items.isNotEmpty && latestEvidence.value == null) {
        latestEvidence.value = items.first;
      }
    } catch (_) {
      // In mock mode or if server not ready
      if (!isMockMode.value && evidenceHistory.isEmpty) {
        evidenceHistory.assignAll(await _mockRepo.getEvidenceTimeline(
          tenantId: selectedTenant.value,
          assetId: selectedAsset.value,
        ));
        if (evidenceHistory.isNotEmpty) {
          latestEvidence.value = evidenceHistory.first;
        }
      }
    }
  }

  void selectEvidence(EvidenceItemModel item) {
    latestEvidence.value = item;
  }
}
