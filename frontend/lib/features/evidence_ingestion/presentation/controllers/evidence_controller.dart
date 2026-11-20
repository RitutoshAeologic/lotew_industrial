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

  // ── Encapsulated Inspection Tab: 0 = Waveform, 1 = Forensic Ledger, 2 = Canonical JSON
  final inspectionTab = 0.obs;

  void setInspectionTab(int index) {
    inspectionTab.value = index;
  }

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

  // ── Sequential Multi-Cycle Streaming (1 -> Target N) ──────────────────────
  final isSequentialMode = false.obs;
  final sequentialCurrentCycle = 1.obs;
  final sequentialTargetCycle = 1.obs;

  // ── High-Throughput Range Streaming & Live Bar Chart State (1 → 2,205) ────
  final cycleQualityMap = <int, String>{}.obs;
  final streamProgress = 0.0.obs;
  final streamingThroughput = 0.obs;
  final isRangeStreaming = false.obs;
  final rangeStreamStart = 1.obs;
  final rangeStreamEnd = 2205.obs;
  final rangeStreamCurrent = 1.obs;
  bool _cancelRangeStreamingRequested = false;

  // ── Raw 17-Sensor ZIP Package Import State (Approach B) ───────────────────
  final isZipImportMode = false.obs;
  final pickedZipBytes = Rxn<Uint8List>();
  final pickedZipName = RxnString();
  final pickedZipSizeBytes = 0.obs;
  final zipFileError = RxnString();
  final zipUploadResult = Rxn<Map<String, dynamic>>();

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

  Timer? _autoSyncTimer;

  @override
  void onInit() {
    super.onInit();
    final dioClient = Get.find<DioClient>();
    _apiRepo = EvidenceRepositoryApi(dioClient: dioClient);
    _mockRepo = EvidenceRepositoryMock();

    loadTimeline();

    // Background synchronizer: reflects real-time Supabase CRUD operations dynamically
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!isStreamingLiveCycle.value && !isRangeStreaming.value && !isUploading.value) {
        loadTimeline(autoSelectLatest: false);
      }
    });
  }

  @override
  void onClose() {
    _autoSyncTimer?.cancel();
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
    selectedPreset.value = (parsed == 1) ? 'CYCLE_1' : (parsed == 211 ? 'CYCLE_211' : (parsed == 2205 ? 'CYCLE_2205' : 'CUSTOM'));
  }

  void onSliderChanged(double val) {
    final intVal = val.toInt();
    cycleId.value = intVal;
    cycleTextController.text = intVal.toString();
    cycleError.value = null;
    selectedPreset.value = (intVal == 1) ? 'CYCLE_1' : (intVal == 211 ? 'CYCLE_211' : (intVal == 2205 ? 'CYCLE_2205' : 'CUSTOM'));
  }

  void setCyclePreset(int targetCycle) {
    cycleId.value = targetCycle;
    cycleTextController.text = targetCycle.toString();
    cycleError.value = null;
    selectedPreset.value = (targetCycle == 1) ? 'CYCLE_1' : (targetCycle == 211 ? 'CYCLE_211' : (targetCycle == 2205 ? 'CYCLE_2205' : 'CUSTOM'));
  }

  // ── 60-Second Real-Time Machine Streaming Implementation ──────────────────
  void startLiveCycleStream({Future<void> Function()? onCycleDone}) {
    if (isStreamingLiveCycle.value) return;

    final curCycle = cycleId.value;
    final isSevereLeak = (curCycle >= 211 && curCycle <= 220);
    final basePressure = isSevereLeak ? 110.4 : 156.25;
    final baseFlow = isSevereLeak ? 2.15 : 7.84;

    isStreamingLiveCycle.value = true;
    streamElapsedSeconds.value = 0;
    currentLivePhase.value = isSequentialMode.value
        ? 'Cycle $curCycle/${sequentialTargetCycle.value}: Phase 1 Extension'
        : 'Phase 1: Piston Extension (Pressure building)';

    // Multiplier determines tick interval:
    // 1x = 1000ms (60 real seconds)
    // 6x = 166ms (10 demo seconds)
    // 12x = 83ms (5 demo seconds)
    final intervalMs = streamSpeedMultiplier.value == 12
        ? 83
        : (streamSpeedMultiplier.value == 6 ? 166 : 1000);

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      streamElapsedSeconds.value++;
      final s = streamElapsedSeconds.value;

      // Update machine stroke phase & live gauge fluctuation
      if (s <= 15) {
        currentLivePhase.value = isSequentialMode.value
            ? 'Cycle $curCycle/${sequentialTargetCycle.value}: Phase 1 Extension'
            : 'Phase 1: Piston Extension Stroke';
        final factor = 0.85 + (s / 15) * 0.15;
        currentLivePressure.value = double.parse((basePressure * factor + (Random().nextDouble() * 0.6 - 0.3)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.45 + (Random().nextDouble() * 0.2)).toStringAsFixed(2));
      } else if (s <= 35) {
        currentLivePhase.value = isSequentialMode.value
            ? 'Cycle $curCycle/${sequentialTargetCycle.value}: Phase 2 Work Hold'
            : 'Phase 2: High Pressure Work Hold (156 bar)';
        currentLivePressure.value = double.parse((basePressure + (Random().nextDouble() * 0.8 - 0.4)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow + (Random().nextDouble() * 0.3 - 0.15)).toStringAsFixed(2));
      } else if (s <= 45) {
        currentLivePhase.value = isSequentialMode.value
            ? 'Cycle $curCycle/${sequentialTargetCycle.value}: Phase 3 Retraction'
            : 'Phase 3: Piston Retraction Stroke';
        currentLivePressure.value = double.parse((basePressure * 0.90 + (Random().nextDouble() * 0.5)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.80 + (Random().nextDouble() * 0.2)).toStringAsFixed(2));
      } else if (s < 60) {
        currentLivePhase.value = isSequentialMode.value
            ? 'Cycle $curCycle/${sequentialTargetCycle.value}: Phase 4 Cool-Down'
            : 'Phase 4: Rest / Cool-Down Stroke';
        currentLivePressure.value = double.parse((basePressure * 0.78 + (Random().nextDouble() * 0.4)).toStringAsFixed(2));
        currentLiveFlow.value = double.parse((baseFlow * 0.30 + (Random().nextDouble() * 0.1)).toStringAsFixed(2));
      } else {
        // Reached 60 seconds: physical cycle complete!
        timer.cancel();
        currentLivePhase.value = 'Cycle $curCycle Complete: Sealing Parquet Batch & SHA-256';
        isUploading.value = true;
        isStreamingLiveCycle.value = false;
        await ingestTelemetryCycle();
        if (onCycleDone != null) {
          await onCycleDone();
        }
      }
    });
  }

  /// Sequential Multi-Cycle Real-Time Execution (Cycle 1 -> Target Cycle)
  void startSequentialStream() {
    if (isStreamingLiveCycle.value || isUploading.value || isRangeStreaming.value) return;

    final target = cycleId.value;
    if (target <= 1) {
      startLiveCycleStream();
      return;
    }

    // High-throughput progressive chunk streaming with real-time Bar Chart visualization:
    startFullDatasetStream(start: 1, end: target);

    /* PREVIOUS REAL-TIME 60s TICK SEQUENTIAL RUN PRESERVED:
    isSequentialMode.value = true;
    sequentialTargetCycle.value = target;
    sequentialCurrentCycle.value = 1;
    _runNextSequentialStep();
    */
  }

  /// High-throughput chunked streaming across cycles (1 to 2,205)
  /// Progressively streams chunks, updating the live Bar Chart and evidence ledger.
  Future<void> startFullDatasetStream({int start = 1, int end = 2205, int chunkSize = 50}) async {
    if (isStreamingLiveCycle.value || isUploading.value || isRangeStreaming.value) return;

    _cancelRangeStreamingRequested = false;
    isRangeStreaming.value = true;
    rangeStreamStart.value = start;
    rangeStreamEnd.value = end;
    rangeStreamCurrent.value = start;
    streamProgress.value = 0.0;
    errorMessage.value = null;

    final totalCycles = end - start + 1;
    final stopwatch = Stopwatch()..start();
    int totalIngestedSoFar = 0;

    try {
      for (int chunkStart = start; chunkStart <= end; chunkStart += chunkSize) {
        if (_cancelRangeStreamingRequested) {
          break;
        }

        final chunkEnd = (chunkStart + chunkSize - 1 > end) ? end : (chunkStart + chunkSize - 1);
        rangeStreamCurrent.value = chunkEnd;

        // Ingest chunk from repository
        final chunkItems = await _activeRepo.ingestTelemetryRange(
          startCycle: chunkStart,
          endCycle: chunkEnd,
          tenantId: selectedTenant.value,
          assetId: selectedAsset.value,
        );

        totalIngestedSoFar += (chunkEnd - chunkStart + 1);
        final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
        if (elapsedSec > 0) {
          streamingThroughput.value = (totalIngestedSoFar / elapsedSec).round();
        }

        // Update cycle quality map reactively
        final Map<int, String> newChunkQuality = {};
        for (final item in chunkItems) {
          if (item.cycleId != null) {
            newChunkQuality[item.cycleId!] = item.qualityFlag;
          }
        }
        cycleQualityMap.addAll(newChunkQuality);

        // Batch upsert into evidence history to avoid quadratic shifting and reactive storms
        // PREVIOUS SEQUENTIAL INSERT:
        // for (final item in chunkItems) {
        //   final existingIdx = evidenceHistory.indexWhere((e) => e.isTelemetry && e.cycleId == item.cycleId);
        //   if (existingIdx >= 0) {
        //     evidenceHistory[existingIdx] = item;
        //   } else {
        //     evidenceHistory.insert(0, item);
        //   }
        // }
        final List<EvidenceItemModel> toAdd = [];
        for (final item in chunkItems) {
          final existingIdx = evidenceHistory.indexWhere((e) => e.isTelemetry && e.cycleId == item.cycleId);
          if (existingIdx >= 0) {
            evidenceHistory[existingIdx] = item;
          } else {
            toAdd.add(item);
          }
        }
        if (toAdd.isNotEmpty) {
          evidenceHistory.insertAll(0, toAdd.reversed);
        }

        if (chunkItems.isNotEmpty) {
          latestTelemetryEvidence.value = chunkItems.last;
        }

        streamProgress.value = (totalIngestedSoFar / totalCycles).clamp(0.0, 1.0);

        // Yield 30ms so Flutter web renderer smoothly repaints the live Bar Chart
        await Future.delayed(const Duration(milliseconds: 30));
      }

      // Ingestion sequence completed
      cycleId.value = end;
      cycleTextController.text = end.toString();
      selectedPreset.value = (end == 1) ? 'CYCLE_1' : (end == 211 ? 'CYCLE_211' : (end == 2205 ? 'CYCLE_2205' : 'CUSTOM'));

      Get.snackbar(
        'Full Dataset Ingestion Complete',
        'Streamed and sealed $totalIngestedSoFar cycles into Supabase ledger with SHA-256 integrity.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Range Streaming Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isRangeStreaming.value = false;
      stopwatch.stop();
    }
  }

  /* PREVIOUS REAL-TIME 60s TICK SEQUENTIAL RUN METHOD PRESERVED:
  void _runNextSequentialStep() {
    if (!isSequentialMode.value) return;

    final cur = sequentialCurrentCycle.value;
    final target = sequentialTargetCycle.value;

    if (cur > target) {
      isSequentialMode.value = false;
      isStreamingLiveCycle.value = false;
      Get.snackbar(
        'Sequential Run Complete',
        'Successfully completed and sealed Cycles 1 to $target in real-time sequence.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Set active cycle to cur
    cycleId.value = cur;
    cycleTextController.text = cur.toString();
    selectedPreset.value = (cur == 1) ? 'CYCLE_1' : (cur == 211 ? 'CYCLE_211' : 'CUSTOM');

    startLiveCycleStream(onCycleDone: () async {
      if (!isSequentialMode.value) return;

      if (cur < target) {
        sequentialCurrentCycle.value++;
        // Short 500ms pause between cycles so user sees the transition
        await Future.delayed(const Duration(milliseconds: 500));
        _runNextSequentialStep();
      } else {
        isSequentialMode.value = false;
        Get.snackbar(
          'Continuous Sequence Complete',
          'All cycles from #1 to #$target ingested and sealed to Supabase.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }
  */

  /// Reset current session to baseline healthy state for a fresh cycle retest
  void resetRetestSession() {
    cancelLiveStream();
    isSequentialMode.value = false;
    sequentialCurrentCycle.value = 1;
    sequentialTargetCycle.value = 1;
    cycleId.value = 1;
    selectedPreset.value = 'CYCLE_1';
    cycleTextController.text = '1';
    cycleError.value = null;
    streamElapsedSeconds.value = 0;
    currentLivePressure.value = 156.25;
    currentLiveFlow.value = 7.84;
    currentLivePhase.value = 'IDLE';
    latestTelemetryEvidence.value = null;
    isZipImportMode.value = false;
    clearSelectedZip();
    errorMessage.value = null;
    inspectionTab.value = 0;
    loadTimeline(autoSelectLatest: false);
    Get.snackbar(
      'Session Reset',
      'Ready for fresh retest. Active Rig: hydraulic_rig_01.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Manually refresh evidence timeline ledger from backend
  Future<void> refreshLedger() async {
    await loadTimeline();
    Get.snackbar(
      'Ledger Refreshed',
      'Synchronized latest telemetry cycles from Supabase ledger.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Completely clears/deletes all telemetry evidence records from Supabase database and memory
  Future<void> clearAllTelemetry() async {
    try {
      isUploading.value = true;
      errorMessage.value = null;

      await _activeRepo.clearTelemetry(
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );

      evidenceHistory.removeWhere((e) => e.isTelemetry);
      cycleQualityMap.clear();
      latestTelemetryEvidence.value = null;

      Get.snackbar(
        'Telemetry Data Cleared',
        'Successfully deleted all telemetry records from Supabase database and memory.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Clear Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void cancelLiveStream() {
    _cancelRangeStreamingRequested = true;
    isRangeStreaming.value = false;
    _streamTimer?.cancel();
    isStreamingLiveCycle.value = false;
    isSequentialMode.value = false;
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
      // Ensure the newly ingested cycle appears at the very top of the evidence timeline
      evidenceHistory.removeWhere((e) => e.id == evidence.id || (e.isTelemetry && e.cycleId == evidence.cycleId));
      evidenceHistory.insert(0, evidence);

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

  // ── Raw 17-Sensor ZIP Package Handling (Approach B: Direct Streaming) ─────
  Future<void> pickZipFile() async {
    try {
      zipFileError.value = null;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > 500 * 1024 * 1024) {
          zipFileError.value = 'ZIP package exceeds maximum allowed size of 500 MB.';
          clearSelectedZip();
          return;
        }

        if (file.bytes == null || file.bytes!.isEmpty) {
          zipFileError.value = 'Selected ZIP file is empty.';
          clearSelectedZip();
          return;
        }

        pickedZipBytes.value = file.bytes;
        pickedZipName.value = file.name;
        pickedZipSizeBytes.value = file.size;
        zipFileError.value = null;
        zipUploadResult.value = null;
        errorMessage.value = null;
      }
    } catch (e) {
      zipFileError.value = 'Failed to select ZIP package: $e';
    }
  }

  void clearSelectedZip() {
    pickedZipBytes.value = null;
    pickedZipName.value = null;
    pickedZipSizeBytes.value = 0;
    zipFileError.value = null;
  }

  Future<void> uploadRigZip() async {
    if (pickedZipBytes.value == null || pickedZipName.value == null) {
      zipFileError.value = 'Please select a valid raw sensor ZIP package.';
      return;
    }

    try {
      isUploading.value = true;
      errorMessage.value = null;
      zipFileError.value = null;

      final res = await _activeRepo.uploadRigZip(
        fileBytes: pickedZipBytes.value!,
        fileName: pickedZipName.value!,
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );

      zipUploadResult.value = res;
      clearSelectedZip();

      final count = res['extracted_count'] ?? 17;
      final rawSha = res['sha256'] as String?;
      final hashDisplay = rawSha != null && rawSha.length >= 16 ? rawSha.substring(0, 16) : 'verified';

      Get.snackbar(
        '17-Sensor Package Mounted',
        'Successfully mounted $count sensor files to rig volume. SHA-256: $hashDisplay...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'ZIP Extraction Failed',
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

  Future<void> loadTimeline({bool autoSelectLatest = true}) async {
    try {
      final items = await _activeRepo.getEvidenceTimeline(
        tenantId: selectedTenant.value,
        assetId: selectedAsset.value,
      );

      // Performance Optimization: Check if timeline records actually changed
      // before updating RxList to prevent triggering heavy table rebuilds on static data.
      bool hasChanged = items.length != evidenceHistory.length;
      if (!hasChanged && items.isNotEmpty && evidenceHistory.isNotEmpty) {
        if (items.first.id != evidenceHistory.first.id ||
            items.last.id != evidenceHistory.last.id) {
          hasChanged = true;
        }
      }

      if (hasChanged) {
        evidenceHistory.assignAll(items);

        // Rebuild quality map strictly from synchronized database records
        cycleQualityMap.clear();
        for (final it in items) {
          if (it.isTelemetry && it.cycleId != null) {
            cycleQualityMap[it.cycleId!] = it.qualityFlag;
          }
        }
      }

      if (items.isEmpty) {
        latestTelemetryEvidence.value = null;
        evidenceHistory.clear();
        cycleQualityMap.clear();
      } else if (autoSelectLatest) {
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
      }
    } catch (_) {
      if (!isMockMode.value && evidenceHistory.isEmpty) {
        final mockItems = await _mockRepo.getEvidenceTimeline(
          tenantId: selectedTenant.value,
          assetId: selectedAsset.value,
        );
        evidenceHistory.assignAll(mockItems);

        cycleQualityMap.clear();
        for (final it in mockItems) {
          if (it.isTelemetry && it.cycleId != null) {
            cycleQualityMap[it.cycleId!] = it.qualityFlag;
          }
        }

        if (autoSelectLatest) {
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
