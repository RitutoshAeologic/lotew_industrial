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

  // Repositories
  late final EvidenceRepository _apiRepo;
  late final EvidenceRepository _mockRepo;
  final isMockMode = false.obs;

  EvidenceRepository get _activeRepo => isMockMode.value ? _mockRepo : _apiRepo;

  // Active view tab: 0 = Telemetry Simulator (Primary), 1 = PDF Upload
  final activeTab = 0.obs;

  // Selected Tenancy
  final selectedTenant = AppConstants.defaultTenantId.obs;
  final selectedAsset = AppConstants.defaultAssetId.obs;

  // ── Telemetry State ──────────────────────────────────────────────────────────
  final cycleId = 1.obs; // 1 to 2,205
  final selectedPreset = 'CYCLE_1'.obs; // 'CYCLE_1', 'CYCLE_211', 'CUSTOM'
  final cycleTextController = TextEditingController(text: '1');
  final cycleError = RxnString();

  // ── PDF Form State ─────────────────────────────────────────────────────────
  final selectedComponent = 'pump'.obs;
  final selectedAction = AppConstants.proposedActions.first.obs;
  final incidentDate = Rx<DateTime>(DateTime.now());
  final notesController = TextEditingController();
  final pickedPdfBytes = Rxn<Uint8List>();
  final pickedPdfName = RxnString();
  final pickedPdfSizeBytes = 0.obs;
  final pdfFileError = RxnString();
  final notesError = RxnString();

  // ── Ingestion Outputs ──────────────────────────────────────────────────────
  final isUploading = false.obs;
  final errorMessage = RxnString();

  final latestTelemetryEvidence = Rxn<EvidenceItemModel>();
  final latestPdfEvidence = Rxn<EvidenceItemModel>();
  final evidenceHistory = <EvidenceItemModel>[].obs;

  /// Current evidence contextually bound to the active tab
  EvidenceItemModel? get currentActiveEvidence =>
      activeTab.value == 0 ? latestTelemetryEvidence.value : latestPdfEvidence.value;

  @override
  void onInit() {
    super.onInit();
    final dioClient = Get.find<DioClient>();
    _apiRepo = EvidenceRepositoryApi(dioClient: dioClient);
    _mockRepo = EvidenceRepositoryMock();

    loadTimeline();
  }

  @override
  void onClose() {
    cycleTextController.dispose();
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
      isMockMode.value ? 'Switched to Offline Mock Mode' : 'Switched to Live Backend API',
      isMockMode.value
          ? 'Operating in simulated mode with realistic SHA-256 and millisecond latency.'
          : 'Connecting to FastAPI backend at http://localhost:8000.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // ── Telemetry Handling & Validation ────────────────────────────────────────
  void onCycleInputChanged(String val) {
    cycleError.value = null;
    final parsed = int.tryParse(val.trim());
    if (parsed == null) {
      cycleError.value = 'Please enter a valid numeric cycle number';
      return;
    }
    if (parsed < 1 || parsed > 2205) {
      cycleError.value = 'Cycle must be between 1 and 2,205';
      return;
    }
    cycleId.value = parsed;
    selectedPreset.value = (parsed == 1) ? 'CYCLE_1' : (parsed == 211 ? 'CYCLE_211' : 'CUSTOM');
  }

  void onSliderChanged(double val) {
    final intVal = val.toInt();
    cycleId.value = intVal;
    cycleTextController.text = intVal.toString();
    cycleError.value = null;
    selectedPreset.value = (intVal == 1) ? 'CYCLE_1' : (intVal == 211 ? 'CYCLE_211' : 'CUSTOM');
  }

  void setCyclePreset(int targetCycle) {
    cycleId.value = targetCycle;
    cycleTextController.text = targetCycle.toString();
    cycleError.value = null;
    selectedPreset.value = (targetCycle == 1) ? 'CYCLE_1' : (targetCycle == 211 ? 'CYCLE_211' : 'CUSTOM');
  }

  Future<void> ingestTelemetryCycle() async {
    if (cycleError.value != null) return;
    if (cycleId.value < 1 || cycleId.value > 2205) {
      cycleError.value = 'Cycle ID out of bounds (1..2205)';
      return;
    }

    try {
      isUploading.value = true;
      errorMessage.value = null;

      final evidence = await _activeRepo.ingestTelemetryCycle(
        cycleId: cycleId.value,
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );

      latestTelemetryEvidence.value = evidence;
      // Insert into history if not already present
      if (!evidenceHistory.any((e) => e.id == evidence.id)) {
        evidenceHistory.insert(0, evidence);
      }

      Get.snackbar(
        'Telemetry Cycle #${cycleId.value} Ingested',
        'Parquet compressed and registered with SHA-256: ${evidence.rawFileSha256.substring(0, 16)}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C2FF),
        colorText: const Color(0xFF0F172A),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Ingestion Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  // ── PDF Handling & Validation ──────────────────────────────────────────────
  Future<void> pickPdfFile() async {
    try {
      pdfFileError.value = null;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Size validation: max 25MB
        if (file.size > 25 * 1024 * 1024) {
          pdfFileError.value = 'File exceeds maximum allowed size of 25 MB.';
          clearSelectedPdf();
          return;
        }

        if (file.bytes == null || file.bytes!.isEmpty) {
          pdfFileError.value = 'Selected file is empty.';
          clearSelectedPdf();
          return;
        }

        pickedPdfBytes.value = file.bytes;
        pickedPdfName.value = file.name;
        pickedPdfSizeBytes.value = file.size;
        pdfFileError.value = null;
        errorMessage.value = null;
      }
    } catch (e) {
      pdfFileError.value = 'Failed to select PDF: $e';
    }
  }

  void clearSelectedPdf() {
    pickedPdfBytes.value = null;
    pickedPdfName.value = null;
    pickedPdfSizeBytes.value = 0;
    pdfFileError.value = null;
  }

  void setIncidentDate(DateTime date) {
    if (date.isAfter(DateTime.now())) {
      Get.snackbar('Invalid Date', 'Incident date cannot be in the future.');
      return;
    }
    incidentDate.value = date;
  }

  Future<void> uploadPdf() async {
    // Validation checks
    if (pickedPdfBytes.value == null || pickedPdfName.value == null) {
      pdfFileError.value = 'Please select a valid PDF file to upload.';
      return;
    }

    if (notesController.text.trim().length > 500) {
      notesError.value = 'Notes cannot exceed 500 characters.';
      return;
    }

    try {
      isUploading.value = true;
      errorMessage.value = null;
      pdfFileError.value = null;
      notesError.value = null;

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

      latestPdfEvidence.value = evidence;
      if (!evidenceHistory.any((e) => e.id == evidence.id)) {
        evidenceHistory.insert(0, evidence);
      }

      clearSelectedPdf();
      notesController.clear();

      Get.snackbar(
        'Documentary Evidence Ingested',
        'SHA-256: ${evidence.rawFileSha256.substring(0, 16)}... committed in ${evidence.processingLatencyMs?.toStringAsFixed(1) ?? "35"} ms',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Upload Error',
        'Could not complete upload: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
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

      // Separate into latest telemetry and latest pdf
      for (final it in items) {
        if (it.isTelemetry && latestTelemetryEvidence.value == null) {
          latestTelemetryEvidence.value = it;
        }
        if (it.isPdf && latestPdfEvidence.value == null) {
          latestPdfEvidence.value = it;
        }
      }
    } catch (_) {
      // In mock mode or if server not ready
      if (!isMockMode.value && evidenceHistory.isEmpty) {
        final mockItems = await _mockRepo.getEvidenceTimeline(
          tenantId: selectedTenant.value,
          assetId: selectedAsset.value,
        );
        evidenceHistory.assignAll(mockItems);
        for (final it in mockItems) {
          if (it.isTelemetry && latestTelemetryEvidence.value == null) {
            latestTelemetryEvidence.value = it;
          }
          if (it.isPdf && latestPdfEvidence.value == null) {
            latestPdfEvidence.value = it;
          }
        }
      }
    }
  }

  void selectEvidence(EvidenceItemModel item) {
    if (item.isTelemetry) {
      latestTelemetryEvidence.value = item;
      activeTab.value = 0;
    } else {
      latestPdfEvidence.value = item;
      activeTab.value = 1;
    }
  }
}
