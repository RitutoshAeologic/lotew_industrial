import 'dart:async';
import 'dart:math';
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

  // Active view tab: 0 = Telemetry Rig Stream, 1 = CSV Ingestion, 2 = PDF Upload
  final activeTab = 0.obs;

  // Selected Tenancy
  final selectedTenant = AppConstants.defaultTenantId.obs;
  final selectedAsset = AppConstants.defaultAssetId.obs;

  // ── Telemetry State ──────────────────────────────────────────────────────────
  final cycleId = 1.obs; // 1 to 2,205
  final selectedPreset = 'CYCLE_1'.obs; // 'CYCLE_1', 'CYCLE_211', 'CUSTOM'
  final cycleTextController = TextEditingController(text: '1');
  final cycleError = RxnString();

  // ── Real-Time 60-Second Machine Streaming Mode ─────────────────────────────
  // Simulates the genuine physical machine execution time (60-second operational cycle)
  final isStreamingLiveCycle = false.obs;
  final streamElapsedSeconds = 0.obs; // 0 to 60
  final streamSpeedMultiplier = 1.obs; // 1 = Real 60s, 6 = Fast 10s Demo, 0 = Instant Batch
  final currentLivePressure = 156.25.obs;
  final currentLiveFlow = 7.84.obs;
  final currentLivePhase = 'IDLE'.obs;
  Timer? _streamTimer;

  // ── CSV Telemetry Form State ───────────────────────────────────────────────
  final pickedCsvBytes = Rxn<Uint8List>();
  final pickedCsvName = RxnString();
  final pickedCsvSizeBytes = 0.obs;
  final csvFileError = RxnString();

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
  final latestCsvEvidence = Rxn<EvidenceItemModel>();
  final latestPdfEvidence = Rxn<EvidenceItemModel>();
  final evidenceHistory = <EvidenceItemModel>[].obs;

  /// Current evidence contextually bound to the active tab
  EvidenceItemModel? get currentActiveEvidence {
    if (activeTab.value == 0) return latestTelemetryEvidence.value;
    if (activeTab.value == 1) return latestCsvEvidence.value;
    return latestPdfEvidence.value;
  }

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
    _streamTimer?.cancel();
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

  // ── 60-Second Real-Time Machine Streaming Implementation ──────────────────
  void startLiveCycleStream() {
    if (isStreamingLiveCycle.value) return;

    final isSevereLeak = (cycleId.value >= 211 && cycleId.value <= 220);
    final basePressure = isSevereLeak ? 110.4 : 156.25;
    final baseFlow = isSevereLeak ? 2.15 : 7.84;

    isStreamingLiveCycle.value = true;
    streamElapsedSeconds.value = 0;
    currentLivePhase.value = 'Phase 1: Piston Extension (Pressure building)';

    // Multiplier determines tick interval:
    // 1x = 1000ms per second (60 real seconds)
    // 6x = 166ms per second (10 demo seconds)
    final intervalMs = streamSpeedMultiplier.value == 6 ? 166 : 1000;

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      streamElapsedSeconds.value++;
      final s = streamElapsedSeconds.value;

      // Update machine stroke phase & live gauge fluctuation
      if (s <= 15) {
        currentLivePhase.value = 'Phase 1: Piston Extension Stroke';
        final factor = 0.85 + (s / 15) * 0.15;
        currentLivePressure.value = double.parse((basePressure * factor + (Random().nextDouble() * 0.6 - 0.3)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.45 + (Random().nextDouble() * 0.2)).toStringAsFixed(2));
      } else if (s <= 35) {
        currentLivePhase.value = 'Phase 2: High Pressure Work Hold (156 bar)';
        currentLivePressure.value = double.parse((basePressure + (Random().nextDouble() * 0.8 - 0.4)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow + (Random().nextDouble() * 0.3 - 0.15)).toStringAsFixed(2));
      } else if (s <= 45) {
        currentLivePhase.value = 'Phase 3: Piston Retraction Stroke';
        currentLivePressure.value = double.parse((basePressure * 0.90 + (Random().nextDouble() * 0.5)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.80 + (Random().nextDouble() * 0.2)).toStringAsFixed(2));
      } else if (s < 60) {
        currentLivePhase.value = 'Phase 4: Rest / Cool-Down Stroke';
        currentLivePressure.value = double.parse((basePressure * 0.78 + (Random().nextDouble() * 0.4)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.30 + (Random().nextDouble() * 0.1)).toStringAsFixed(2));
      } else {
        // Reached 60 seconds: physical cycle complete!
        timer.cancel();
        isStreamingLiveCycle.value = false;
        currentLivePhase.value = 'Cycle Complete: Sealing Parquet Batch & SHA-256';
        ingestTelemetryCycle();
      }
    });
  }

  void cancelLiveStream() {
    _streamTimer?.cancel();
    isStreamingLiveCycle.value = false;
    currentLivePhase.value = 'Stream Cancelled';
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
      if (!evidenceHistory.any((e) => e.id == evidence.id)) {
        evidenceHistory.insert(0, evidence);
      }

      Get.snackbar(
        'Telemetry Cycle #${cycleId.value} Sealed & Ingested',
        '60s batch compressed to Parquet. SHA-256: ${evidence.rawFileSha256.substring(0, 16)}...',
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

  // ── CSV Telemetry Handling & Validation ────────────────────────────────────
  Future<void> pickCsvFile() async {
    try {
      csvFileError.value = null;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > 50 * 1024 * 1024) {
          csvFileError.value = 'CSV file exceeds maximum allowed size of 50 MB.';
          clearSelectedCsv();
          return;
        }

        if (file.bytes == null || file.bytes!.isEmpty) {
          csvFileError.value = 'Selected CSV file is empty.';
          clearSelectedCsv();
          return;
        }

        pickedCsvBytes.value = file.bytes;
        pickedCsvName.value = file.name;
        pickedCsvSizeBytes.value = file.size;
        csvFileError.value = null;
        errorMessage.value = null;
      }
    } catch (e) {
      csvFileError.value = 'Failed to select CSV: $e';
    }
  }

  void clearSelectedCsv() {
    pickedCsvBytes.value = null;
    pickedCsvName.value = null;
    pickedCsvSizeBytes.value = 0;
    csvFileError.value = null;
  }

  Future<void> uploadCsv() async {
    if (pickedCsvBytes.value == null || pickedCsvName.value == null) {
      csvFileError.value = 'Please select a valid CSV telemetry file.';
      return;
    }

    try {
      isUploading.value = true;
      errorMessage.value = null;
      csvFileError.value = null;

      final evidence = await _activeRepo.uploadCsv(
        fileBytes: pickedCsvBytes.value!,
        fileName: pickedCsvName.value!,
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
        componentId: selectedComponent.value,
      );

      latestCsvEvidence.value = evidence;
      if (!evidenceHistory.any((e) => e.id == evidence.id)) {
        evidenceHistory.insert(0, evidence);
      }

      clearSelectedCsv();

      Get.snackbar(
        'CSV Telemetry Ingested',
        'Continuous sensor columns compressed to Parquet. SHA-256: ${evidence.rawFileSha256.substring(0, 16)}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'CSV Ingestion Error',
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

      for (final it in items) {
        if (it.isTelemetry && latestTelemetryEvidence.value == null) {
          latestTelemetryEvidence.value = it;
        }
        if (it.evidenceType == 'CSV_TELEMETRY' && latestCsvEvidence.value == null) {
          latestCsvEvidence.value = it;
        }
        if (it.isPdf && latestPdfEvidence.value == null) {
          latestPdfEvidence.value = it;
        }
      }
    } catch (_) {
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
          if (it.evidenceType == 'CSV_TELEMETRY' && latestCsvEvidence.value == null) {
            latestCsvEvidence.value = it;
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
    } else if (item.evidenceType == 'CSV_TELEMETRY') {
      latestCsvEvidence.value = item;
      activeTab.value = 1;
    } else {
      latestPdfEvidence.value = item;
      activeTab.value = 2;
    }
  }
}
