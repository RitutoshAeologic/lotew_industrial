import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/controllers/persona_controller.dart';
import '../../../../core/network/dio_client.dart';

class ReplayTrajectoryItem {
  final String timestampUtc;
  final int cycleId;
  final String eventType;
  final String title;
  final String detail;
  final String status;
  final String? evidenceSha256;
  final String hardwareOriginId;

  const ReplayTrajectoryItem({
    required this.timestampUtc,
    required this.cycleId,
    required this.eventType,
    required this.title,
    required this.detail,
    required this.status,
    this.evidenceSha256,
    required this.hardwareOriginId,
  });

  factory ReplayTrajectoryItem.fromJson(Map<String, dynamic> json) {
    return ReplayTrajectoryItem(
      timestampUtc: json['timestamp_utc'] ?? '',
      cycleId: json['cycle_id'] ?? 0,
      eventType: json['event_type'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      status: json['status'] ?? 'NOMINAL',
      evidenceSha256: json['evidence_sha256'],
      hardwareOriginId: json['hardware_origin_id'] ?? 'HW-HYD-RIG-01-PRIMARY-BUS',
    );
  }
}

class ClaimReplayController extends GetxController {
  static ClaimReplayController get to => Get.find();

  final cutoffCycle = 211.obs;
  final isLoading = false.obs;

  // Decision Record State
  final decisionId = 'DEC-2026-HYD-0211'.obs;
  final verdict = 'DENY_INDEMNITY'.obs;
  final triageAction = 'ACT'.obs; // 'ACT', 'WAIT', 'GET_MORE_EVIDENCE'
  final whyCode = 'WILLFUL_DISREGARD_WITH_ZERO_MAINTENANCE'.obs;
  final whatWouldChangeThis = 'Submission of certified CMMS technician work order dated before Cycle 215.'.obs;
  final authorityScore = 0.94.obs;
  final adherenceFollowed = false.obs;
  final serviceMissed = true.obs;
  final breachedClauses = <String>[
    'Clause 3.1: Mandatory Maintenance & Service Adherence Compliance',
    'Clause 4.2: Failure to Mitigate Loss Upon Telematics Alarm',
  ].obs;
  final rationaleSummary = ''.obs;
  final trajectory = <ReplayTrajectoryItem>[].obs;
  final canonicalSha256 = '97dea224d252729001e60883c77c4c3158b13572388d6d6212a3f7eabebe8133'.obs;
  final blockHash = 'd4f728124583688ad03ae2508c2ab94cff8149bc81c19c6edcc5dccaffa99f8c'.obs;
  final prevHash = '7f8b92c48100ae981744bc7a10992381992014ff912a781994cba012a91284ba'.obs;

  // Determination State
  final determinationStatus = 'PENDING'.obs; // 'PENDING', 'DENIED', 'APPROVED'
  final adjusterNotesController = TextEditingController(
    text: 'Operator willfully dismissed Cycle 211 pump leak alarm. No maintenance work order raised. Claim Denied per Clause 3.1 & Clause 4.2.',
  );
  final isSubmittingDetermination = false.obs;

  @override
  void onInit() {
    super.onInit();
    evaluateReplay(cutoffCycle.value);

    // Dynamic State Linkage: When operator changes alert action in Console 1,
    // automatically re-evaluate Claim Replay in Console 2!
    if (Get.isRegistered<PersonaController>()) {
      ever(PersonaController.to.isAlertDismissed, (_) {
        evaluateReplay(cutoffCycle.value);
      });
      ever(PersonaController.to.isServiceDispatched, (_) {
        evaluateReplay(cutoffCycle.value);
      });
    }
  }

  Future<void> evaluateReplay(int cycle) async {
    cutoffCycle.value = cycle;
    isLoading.value = true;

    try {
      final dioClient = Get.find<DioClient>();
      final res = await dioClient.dio.post(
        '/api/v1/industrial/replay/evaluate',
        data: {
          'tenant_id': 'TEN-TITAN-01',
          'asset_id': 'hydraulic_rig_01',
          'cutoff_cycle': cycle,
          'user_role': 'INSURER_ADJUSTER',
          'insurer_id': 'INS-ALLIANZ-01',
        },
      );

      if (res.data != null) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        decisionId.value = data['decision_id'] ?? '';
        verdict.value = data['verdict'] ?? '';
        authorityScore.value = (data['authority_score'] as num?)?.toDouble() ?? 0.0;
        adherenceFollowed.value = data['adherence_followed'] ?? false;
        serviceMissed.value = data['service_missed'] ?? true;
        rationaleSummary.value = data['rationale_summary'] ?? '';
        canonicalSha256.value = data['canonical_data_sha256'] ?? '';
        blockHash.value = data['block_hash'] ?? '';
        prevHash.value = data['previous_hash'] ?? '';

        final rawClauses = data['breached_clauses'] as List?;
        if (rawClauses != null) {
          breachedClauses.assignAll(rawClauses.map((e) => e.toString()).toList());
        }

        final rawTrajectory = data['reconstructed_trajectory'] as List?;
        if (rawTrajectory != null) {
          trajectory.assignAll(
            rawTrajectory.map((e) => ReplayTrajectoryItem.fromJson(Map<String, dynamic>.from(e))).toList(),
          );
        }
      }
    } catch (e) {
      // Robust offline fallback so UI never blocks
      _evaluateOfflineFallback(cycle);
    } finally {
      isLoading.value = false;
    }
  }

  void _evaluateOfflineFallback(int cycle) {
    final personaCtrl = PersonaController.to;
    final isNegligent = personaCtrl.isAlertDismissed.value;

    final items = <ReplayTrajectoryItem>[
      const ReplayTrajectoryItem(
        timestampUtc: '2024-01-01T09:00:00Z',
        cycleId: 1665,
        eventType: 'BASELINE_HANDOVER',
        title: 'Pre-Rental Handover Baseline Verification',
        detail: 'Cooler: 100%, Pump Leak: 0.0, FS1 Flow: 19.2 L/min, PS1: 155.0 bar, Temp: 34.0°C. Baseline Certified Nominal.',
        status: 'NOMINAL',
        evidenceSha256: '53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c',
        hardwareOriginId: 'HW-HYD-RIG-01-PRIMARY-BUS',
      ),
    ];

    if (cycle >= 211) {
      items.add(
        const ReplayTrajectoryItem(
          timestampUtc: '2024-01-01T14:00:00Z',
          cycleId: 211,
          eventType: 'TELEMETRY_ALERT',
          title: 'ISO-13374 Level 2 Alarm: Pump Leak Detected',
          detail: 'Flow FS1 collapsed from 19.2 to 17.5 L/min (-1.7 L/min slippage). PS1 dropped from 155 to 145 bar. 2.0-hr Service SLA triggered.',
          status: 'WARNING',
          evidenceSha256: '8f3b1409ae221dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042dc012',
          hardwareOriginId: 'HW-HYD-RIG-01-PRIMARY-BUS',
        ),
      );
      items.add(
        ReplayTrajectoryItem(
          timestampUtc: '2024-01-01T14:02:15Z',
          cycleId: 211,
          eventType: 'OPERATOR_ACTION',
          title: 'In-Cab Telematics Alert Delivery & Operator Response',
          detail: isNegligent
              ? 'Alert delivered to OEM cab display. Action: Operator clicked [ Dismiss Alert & Run ].'
              : 'Alert delivered to OEM cab display. Action: Operator clicked [ Dispatch Service Ticket ].',
          status: isNegligent ? 'DISMISSED' : 'DELIVERED',
          evidenceSha256: 'e112ab89124430198ca128091244fa781299ab124800114a4b49195b0042dc11',
          hardwareOriginId: 'HW-CAB-DISPLAY-CONSOLE-01',
        ),
      );
      items.add(
        ReplayTrajectoryItem(
          timestampUtc: '2024-01-01T14:06:00Z',
          cycleId: 211,
          eventType: 'CMMS_QUERY',
          title: 'ERP / CMMS Maintenance Dispatch Query',
          detail: isNegligent
              ? 'Query: Search for technician work order on Rig #01. Result: ZERO WORK ORDERS FOUND.'
              : 'Query: Search for technician work order on Rig #01. Result: WORK ORDER #WO-9912 FOUND.',
          status: isNegligent ? 'MISSING_RECORD' : 'NOMINAL',
          evidenceSha256: '4412bc78019941a8b120481239aa812fbc12498114a4b49195b0042da0994112',
          hardwareOriginId: 'CMMS-TITAN-ERP-DATABASE',
        ),
      );
    }

    if (cycle >= 226) {
      items.add(
        const ReplayTrajectoryItem(
          timestampUtc: '2024-01-01T17:15:00Z',
          cycleId: 226,
          eventType: 'FAILURE',
          title: 'Catastrophic Hydraulic Pump Seizure',
          detail: 'Total flow collapse (FS1 = 0.0 L/min). Complete mechanical seizure. \$18,500 replacement cost.',
          status: 'FAILURE',
          evidenceSha256: '9900ab124400114a4b49195b0042da09c77113bdf2d0014a4b49195b0042da09',
          hardwareOriginId: 'HW-HYD-RIG-01-PRIMARY-BUS',
        ),
      );
    }

    trajectory.assignAll(items);

    if (cycle < 211) {
      triageAction.value = 'WAIT / GET_MORE_EVIDENCE';
      verdict.value = 'AWAIT_INCIDENT_TIMELINE';
      authorityScore.value = 0.65;
      whyCode.value = 'PRE_INCIDENT_NOMINAL_BASELINE';
      whatWouldChangeThis.value = 'Scrub timeline forward to Cycle 211 alarm to evaluate telematics response.';
      adherenceFollowed.value = true;
      serviceMissed.value = false;
      breachedClauses.clear();
      rationaleSummary.value =
          'Rig #01 is within certified nominal pre-rental baseline (Cycle 1665). No breach knowable at this cutoff.';
    } else if (isNegligent) {
      triageAction.value = 'ACT';
      verdict.value = 'DENY_INDEMNITY';
      authorityScore.value = 0.94;
      whyCode.value = 'WILLFUL_DISREGARD_WITH_ZERO_MAINTENANCE';
      whatWouldChangeThis.value =
          'Submission of verified CMMS technician dispatch work order timestamped before Cycle 215.';
      adherenceFollowed.value = false;
      serviceMissed.value = true;
      breachedClauses.assignAll([
        'Clause 3.1: Mandatory Maintenance & Service Adherence Compliance',
        'Clause 4.2: Failure to Mitigate Loss Upon Telematics Alarm',
      ]);
      rationaleSummary.value =
          'Forensic trajectory confirms operator dismissed Cycle 211 pump leak alarm without dispatching maintenance. Claim Denied.';
    } else {
      triageAction.value = 'ACT';
      verdict.value = 'APPROVE_INDEMNITY';
      authorityScore.value = 0.98;
      whyCode.value = 'MAINTENANCE_DUE_DILIGENCE_COMPLIED';
      whatWouldChangeThis.value = 'None. Loss is covered under standard policy terms.';
      adherenceFollowed.value = true;
      serviceMissed.value = false;
      breachedClauses.clear();
      rationaleSummary.value = 'Operator adhered to maintenance standard. Loss covered under manufacturer warranty.';
    }
  }

  Future<void> submitDetermination(String determination) async {
    isSubmittingDetermination.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      await dioClient.dio.post(
        '/api/v1/industrial/claims/determine',
        data: {
          'claim_id': 'CLM-2026-9042',
          'decision_id': decisionId.value,
          'determination': determination,
          'clause_referenced': breachedClauses.join(' & '),
          'adjuster_notes': adjusterNotesController.text,
          'adjuster_user_id': 'claims@allianz.com',
        },
      );
      determinationStatus.value = determination;
      Get.snackbar(
        determination == 'DENIED' ? 'Claim Denied' : 'Payout Approved',
        determination == 'DENIED'
            ? 'Official rejection order recorded and locked into cryptographic hash chain.'
            : 'Payout of \$18,500.00 approved for settlement.',
        backgroundColor: determination == 'DENIED' ? Colors.red.shade900 : Colors.green.shade900,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      determinationStatus.value = determination;
      Get.snackbar(
        determination == 'DENIED' ? 'Claim Denied (Local)' : 'Payout Approved (Local)',
        'Determination recorded successfully in active session.',
        backgroundColor: determination == 'DENIED' ? Colors.red.shade900 : Colors.green.shade900,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSubmittingDetermination.value = false;
    }
  }

  void downloadDossier() {
    const url = '${AppConstants.apiBaseUrl}/api/v1/industrial/claims/CLM-2026-9042/dossier';
    Get.snackbar(
      'Exporting Forensic Dossier',
      'Downloading self-contained ZIP archive ($url)...',
      backgroundColor: Colors.indigo.shade900,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
