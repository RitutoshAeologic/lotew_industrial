import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/controllers/persona_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/telemetry_waveform_chart.dart';

class EvidenceConsoleScreen extends StatelessWidget {
  const EvidenceConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clean Executive Screen Header ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.precision_manufacturing_rounded, size: 14, color: Color(0xFFD97706)),
                              SizedBox(width: 6),
                              Text(
                                'OEM IN-CAB TELEMATICS TERMINAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🚨 ALARM ACTIVE: PUMP LEAK',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Excavator Rig #01 • Fleet Health & Telematics',
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Integrated OEM Cab Display / PWA Terminal • Asset: Excavator Rig #01 (Zero Edge Hardware Added)',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_rounded, size: 16, color: AppColors.success),
                      SizedBox(width: 6),
                      Text(
                        'Telematics Feed: LIVE (Rig #01)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Top 4 KPI Metrics Row ─────────────────────────────────────────
            const _FleetKpiMetricsRow(),
            const SizedBox(height: AppSpacing.lg),

            // ── Active Service & Maintenance Alert (Primary Focus) ────────────
            const _ActiveServiceAlertCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── Pre-Rental Handover Baseline Card (Legal Delivery Proof) ──────
            const _HandoverBaselineCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── Live Rig Telemetry & Diagnostic Chart ─────────────────────────
            const _LiveTelemetryDiagnosticsCard(),
          ],
        ),
      ),
    );
  }
}

// ── Top 4 KPI Metric Cards ────────────────────────────────────────────────────
class _FleetKpiMetricsRow extends StatelessWidget {
  const _FleetKpiMetricsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildMetricTile(
              label: 'MONITORED ASSET',
              value: 'Excavator Rig #01',
              subValue: 'ID: hydraulic_rig_01',
              icon: Icons.precision_manufacturing_rounded,
              accentColor: AppColors.primaryDark,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'MAIN PUMP PRESSURE',
              value: '145.0 bar',
              subValue: 'Sensor PS1 (Nominal: 155.0 bar)',
              icon: Icons.speed_rounded,
              accentColor: AppColors.danger,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'PUMP LEAK FLOW RATE',
              value: '17.5 L/min',
              subValue: 'Flow FS1 (-1.7 L/min slippage)',
              icon: Icons.water_drop_rounded,
              accentColor: AppColors.danger,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'POLICY SERVICE SLA',
              value: '⏱️ 2.0 Operating Hours',
              subValue: 'Mandatory Service Window',
              icon: Icons.timer_outlined,
              accentColor: AppColors.warning,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width < 220 ? double.infinity : width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subValue,
                  style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Service & Maintenance Alert (Realistic Operator Action) ────────────
class _ActiveServiceAlertCard extends StatelessWidget {
  const _ActiveServiceAlertCard();

  @override
  Widget build(BuildContext context) {
    final personaCtrl = PersonaController.to;

    return Obx(() {
      final isDispatched = personaCtrl.isServiceDispatched.value;
      final borderColor = isDispatched ? AppColors.success : AppColors.danger;
      final bgColor = isDispatched ? AppColors.success.withValues(alpha: 0.05) : AppColors.danger.withValues(alpha: 0.05);

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDispatched ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: borderColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDispatched
                              ? 'SERVICE WORK ORDER #WO-9912 DISPATCHED'
                              : 'HIGH PRIORITY ALARM: HYDRAULIC PUMP INTERNAL LEAK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Triggered at Cycle #211 (14:00 UTC) • Severity: ISO-13374 Level 2 Critical Alarm',
                          style: TextStyle(fontSize: 11, color: AppColors.slate600),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDispatched ? 'STATUS: MITIGATED' : 'SLA: 2.0 Operating Hours',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Continuous internal fluid slippage detected in Main Hydraulic Axial Piston Pump. Flow collapsed from baseline 19.2 to 17.5 L/min with pressure dropping from 155.0 to 145.0 bar and oil temp rising to 37.5°C. Continued heavy excavation duty under active alert directly causes metal friction seizure and voids insurance coverage under Policy Clause 3.1 & 4.2.',
              style: TextStyle(fontSize: 12, color: AppColors.slate800, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),

            // Operator Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: personaCtrl.dispatchService,
                  icon: const Icon(Icons.build_circle_rounded, size: 16),
                  label: const Text('🛠️ Dispatch Field Service Technician'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: personaCtrl.dismissAlert,
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  label: const Text('⚠️ Dismiss Alert & Continue Operating'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            if (personaCtrl.alertActionFeedback.value.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(isDispatched ? Icons.verified_rounded : Icons.info_outline_rounded, color: borderColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        personaCtrl.alertActionFeedback.value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Pre-Rental Handover Baseline Card (Legal Proof) ───────────────────────────
class _HandoverBaselineCard extends StatelessWidget {
  const _HandoverBaselineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PRE-RENTAL HANDOVER CERTIFICATE (PROOF OF NOMINAL DELIVERY)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('100% NOMINAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  '• Handover Baseline (Cycle #1665 at 09:00 UTC): Cooler: 100%, Internal Leak: 0.0 L/min, Flow: 19.2 L/min, Pressure: 155.0 bar, Temp: 34.0°C.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate900),
                ),
                const SizedBox(height: 2),
                const Text(
                  '• Cryptographic Baseline Seal: sha256:53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c (Proves rig was undamaged when delivered).',
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.slate500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Diagnostics & Telemetry Card ─────────────────────────────────────────
class _LiveTelemetryDiagnosticsCard extends StatelessWidget {
  const _LiveTelemetryDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, size: 20, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Hydraulic Rig Diagnostic Waveforms (Sensor Bus)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Rig #01 • 17 Telematics Channels Synced',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Continuous stream from Main Hydraulic Axial Piston Pump showing pressure (PS1), secondary pressure (PS2), and internal volume flow (FS1).',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),

          // Waveform Chart Component
          const SizedBox(
            height: 280,
            child: TelemetryWaveformChart(cycleId: 211, isSevereLeak: true),
          ),
        ],
      ),
    );
  }
}
