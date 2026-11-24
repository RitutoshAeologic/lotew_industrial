import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/controllers/persona_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/claim_replay_controller.dart';

class ClaimReplayScreen extends StatefulWidget {
  const ClaimReplayScreen({super.key});

  @override
  State<ClaimReplayScreen> createState() => _ClaimReplayScreenState();
}

class _ClaimReplayScreenState extends State<ClaimReplayScreen> {
  bool _showRawHashes = false;

  @override
  Widget build(BuildContext context) {
    final controller = ClaimReplayController.to;
    final personaCtrl = PersonaController.to;

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Executive Screen Header ───────────────────────────────────────
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
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel_rounded, size: 14, color: Color(0xFF0F766E)),
                              SizedBox(width: 6),
                              Text(
                                'DISPUTE ADJUDICATION PORTAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Obx(() => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: personaCtrl.currentPersona.value.badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                personaCtrl.currentPersona.value.name,
                                style: TextStyle(
                                  color: personaCtrl.currentPersona.value.badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Dispute Investigation: Claim CLM-2026-9042',
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Point-in-Time Retrospective Audit • Rig #01 Catastrophic Hydraulic Pump Failure',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => controller.evaluateReplay(controller.cutoffCycle.value),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Re-Evaluate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate800,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: controller.downloadDossier,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export Legal Dossier ZIP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.slate900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Dispute Metadata Executive Grid ──────────────────────────────
            const _DisputeSummaryGrid(),
            const SizedBox(height: AppSpacing.lg),

            // ── Executive 3-Stage Investigation Stepper (Retrospective Slider)
            _InvestigationStepperCard(controller: controller),
            const SizedBox(height: AppSpacing.lg),

            // ── Two Columns: Trajectory Evidence vs Automated Verdict ────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 980;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _TrajectoryEvidenceCard(
                          controller: controller,
                          showHashes: _showRawHashes,
                          onToggleHashes: () {
                            setState(() {
                              _showRawHashes = !_showRawHashes;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 5,
                        child: _AuthorityVerdictAndDeterminationCard(controller: controller),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _AuthorityVerdictAndDeterminationCard(controller: controller),
                      const SizedBox(height: AppSpacing.lg),
                      _TrajectoryEvidenceCard(
                        controller: controller,
                        showHashes: _showRawHashes,
                        onToggleHashes: () {
                          setState(() {
                            _showRawHashes = !_showRawHashes;
                          });
                        },
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Standalone Dossier & Cryptographic Assurance Footer Card ──────
            _CryptographicProofCard(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ── Dispute Metadata 5-Column Summary Card ───────────────────────────────────
class _DisputeSummaryGrid extends StatelessWidget {
  const _DisputeSummaryGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.report_problem_rounded, color: AppColors.danger, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          const Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _HeaderMetadataItem(
                  label: 'CLAIMED DAMAGE AMOUNT',
                  value: '\$18,500.00 USD',
                  valueColor: AppColors.danger,
                  isBold: true,
                ),
                _HeaderMetadataItem(
                  label: 'INSURANCE POLICY',
                  value: '#POL-ALLZ-8812 (Allianz SE)',
                  isBold: true,
                ),
                _HeaderMetadataItem(
                  label: 'EQUIPMENT ASSET',
                  value: 'Excavator Rig #01',
                  subValue: 'hydraulic_rig_01',
                ),
                _HeaderMetadataItem(
                  label: 'OPERATOR / LESSEE',
                  value: 'Titan Rentals Heavy',
                  subValue: 'ABC Infrastructure',
                ),
                _HeaderMetadataItem(
                  label: 'REPORTED EVENT',
                  value: 'Hydraulic Pump Seizure',
                  subValue: 'Cycle #226 (Unserviced)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;
  final bool isBold;

  const _HeaderMetadataItem({
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.slate900,
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 1),
          Text(
            subValue!,
            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
          ),
        ],
      ],
    );
  }
}

// ── 3-Milestone Investigation Story Stepper ──────────────────────────────────
class _InvestigationStepperCard extends StatelessWidget {
  final ClaimReplayController controller;

  const _InvestigationStepperCard({required this.controller});

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
                  Icon(Icons.history_toggle_off_rounded, size: 20, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Retrospective Time-Travel Investigation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.slate900,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CUTOFF: CYCLE #${controller.cutoffCycle.value} (Facts Knowable strictly at t ≤ ${controller.cutoffCycle.value})',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Scrub backwards to reconstruct what was legally and physically knowable at each milestone. All future telemetry and failure data past Cutoff Time T is quarantined to eliminate hindsight bias.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── The 3 Milestone Cards ──────────────────────────────────────────
          Obx(() {
            final active = controller.cutoffCycle.value;

            return Row(
              children: [
                Expanded(
                  child: _MilestonePhaseCard(
                    stepNumber: '1',
                    title: 'Baseline Handover',
                    cycleLabel: 'Cycle #1665 (09:00 UTC)',
                    statusLabel: 'CERTIFIED NOMINAL',
                    statusColor: AppColors.success,
                    icon: Icons.check_circle_rounded,
                    description: 'Prerelease inspection nominal. 0.0 L/min internal leakage. 100% health.',
                    isSelected: active == 1665,
                    onTap: () => controller.evaluateReplay(1665),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MilestonePhaseCard(
                    stepNumber: '2',
                    title: 'Incident: Pump Leak Alarm',
                    cycleLabel: 'Cycle #211 (14:00 UTC)',
                    statusLabel: 'OPERATOR DISMISSED ALARM',
                    statusColor: AppColors.danger,
                    icon: Icons.warning_amber_rounded,
                    description: 'Flow collapsed to 2.15 L/min. Operator bypassed alert and continued running unserviced.',
                    isSelected: active == 211,
                    onTap: () => controller.evaluateReplay(211),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MilestonePhaseCard(
                    stepNumber: '3',
                    title: 'Catastrophic Seizure',
                    cycleLabel: 'Cycle #226 (17:15 UTC)',
                    statusLabel: 'PUMP SEIZURE DISASTER',
                    statusColor: AppColors.danger,
                    icon: Icons.cancel_rounded,
                    description: 'Total mechanical seizure after 14 unserviced hours. \$18,500 damage claim filed.',
                    isSelected: active == 226,
                    onTap: () => controller.evaluateReplay(226),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.md),

          // ── Fine-Grained Cutoff Slider ─────────────────────────────────────
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Continuous Cutoff Scrubbing (t ≤ T):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate700),
                      ),
                      Text(
                        'Cycle ${controller.cutoffCycle.value}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate900),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: controller.cutoffCycle.value >= 211 ? AppColors.danger : AppColors.success,
                      thumbColor: controller.cutoffCycle.value >= 211 ? AppColors.danger : AppColors.success,
                      inactiveTrackColor: AppColors.slate200,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: controller.cutoffCycle.value == 1665 ? 100.0 : controller.cutoffCycle.value.toDouble(),
                      min: 100.0,
                      max: 226.0,
                      divisions: 126,
                      onChanged: (val) {
                        final target = val.round() == 100 ? 1665 : val.round();
                        controller.evaluateReplay(target);
                      },
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _MilestonePhaseCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String cycleLabel;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _MilestonePhaseCard({
    required this.stepNumber,
    required this.title,
    required this.cycleLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slate900 : AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.slate900 : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
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
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.slate300,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.slate900 : AppColors.slate800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cycleLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.slate300 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
                Icon(icon, size: 16, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : statusColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.slate300 : AppColors.slate600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reconstructed Fact Trajectory Timeline Card ──────────────────────────────
class _TrajectoryEvidenceCard extends StatelessWidget {
  final ClaimReplayController controller;
  final bool showHashes;
  final VoidCallback onToggleHashes;

  const _TrajectoryEvidenceCard({
    required this.controller,
    required this.showHashes,
    required this.onToggleHashes,
  });

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
                  Icon(Icons.format_list_bulleted_rounded, size: 20, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Reconstructed Evidence Trajectory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onToggleHashes,
                icon: Icon(showHashes ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 14),
                label: Text(showHashes ? 'Hide Technical Hashes' : 'Show SHA-256 Hashes'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.slate700,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Cross-corroboration of physical machine telemetry, cabin alerts, and maintenance work orders strictly at t ≤ T.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),

          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.trajectory.isEmpty) {
              return const Center(child: Text('No evidence recorded at this cutoff.'));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.trajectory.length,
              separatorBuilder: (_, __) => const Divider(height: 20, color: AppColors.slate100),
              itemBuilder: (context, index) {
                final item = controller.trajectory[index];
                return _TrajectoryRowItem(item: item, showHash: showHashes);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _TrajectoryRowItem extends StatelessWidget {
  final ReplayTrajectoryItem item;
  final bool showHash;

  const _TrajectoryRowItem({required this.item, required this.showHash});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (item.status) {
      case 'NOMINAL':
      case 'DELIVERED':
        iconColor = AppColors.success;
        iconBg = AppColors.success.withValues(alpha: 0.12);
        icon = Icons.check_circle_rounded;
        break;
      case 'WARNING':
        iconColor = AppColors.warning;
        iconBg = AppColors.warning.withValues(alpha: 0.12);
        icon = Icons.warning_rounded;
        break;
      case 'DISMISSED':
      case 'MISSING_RECORD':
      case 'FAILURE':
      default:
        iconColor = AppColors.danger;
        iconBg = AppColors.danger.withValues(alpha: 0.12);
        icon = Icons.cancel_rounded;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate900),
                    ),
                  ),
                  Text(
                    'Cycle #${item.cycleId} • ${item.timestampUtc.replaceFirst('T', ' ').replaceFirst('Z', ' UTC')}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.slate500),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.detail,
                style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.35),
              ),
              if (showHash) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory_rounded, size: 12, color: AppColors.slate600),
                          const SizedBox(width: 4),
                          Text(
                            'Origin: ${item.hardwareOriginId}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.slate600),
                          ),
                        ],
                      ),
                      if (item.evidenceSha256 != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 12, color: AppColors.slate600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'SHA-256: ${item.evidenceSha256}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppColors.slate600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Automated Recommendation & Human Determination Card ──────────────────────
class _AuthorityVerdictAndDeterminationCard extends StatelessWidget {
  final ClaimReplayController controller;

  const _AuthorityVerdictAndDeterminationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 1. Lotew Automated Recommendation Banner ─────────────────────────
        Obx(() {
          final isDenied = controller.verdict.value == 'DENY_INDEMNITY';
          final badgeColor = isDenied ? AppColors.danger : AppColors.success;

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
                    Row(
                      children: [
                        const Text(
                          '3-WAY TRIAGE: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.slate900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.triageAction.value,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Confidence: ${(controller.authorityScore.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isDenied ? Icons.block_rounded : Icons.check_circle_rounded, color: badgeColor, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isDenied ? 'RECOMMEND CLAIM DENIAL' : 'RECOMMEND CLAIM APPROVAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  controller.rationaleSummary.value,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.4),
                ),
                if (controller.breachedClauses.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'BREACHED POLICY CLAUSES:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  ...controller.breachedClauses.map((clause) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                clause,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('WHY CODE: ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate500)),
                          Text(controller.whyCode.value, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WHAT WOULD CHANGE THIS: ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate500)),
                          Expanded(
                            child: Text(controller.whatWouldChangeThis.value, style: const TextStyle(fontSize: 10, color: AppColors.slate700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),

        // ── 2. Adjuster Human Fiduciary Determination (The 2 Buttons) ─────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.draw_rounded, size: 18, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Adjuster Final Adjudication (Sign-Off)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Execute legally binding determination. Cryptographically seals claim decision to the hash ledger.',
                style: TextStyle(fontSize: 11, color: AppColors.slate600),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: controller.adjusterNotesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, color: AppColors.slate900),
                decoration: InputDecoration(
                  labelText: 'Adjuster Findings / Rationale',
                  labelStyle: const TextStyle(fontSize: 12, color: AppColors.slate600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: AppColors.bgLight,
                  filled: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // The 2 Exclusive Action Buttons
              Obx(() {
                if (controller.isSubmittingDetermination.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                }

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.submitDetermination('DENIED'),
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: const Text('❌ Confirm Claim Denial'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.submitDetermination('APPROVED'),
                        icon: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        label: const Text('🟢 Approve Payout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Verification Seal Banner
              Obx(() {
                final status = controller.determinationStatus.value;
                if (status == 'PENDING') return const SizedBox.shrink();

                final isDenied = status == 'DENIED';
                return Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDenied ? AppColors.danger.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDenied ? AppColors.danger : AppColors.success),
                  ),
                  child: Row(
                    children: [
                      Icon(isDenied ? Icons.lock_rounded : Icons.verified_rounded, color: isDenied ? AppColors.danger : AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isDenied
                              ? 'ADJUDICATED: CLAIM OFFICIALLY DENIED by Allianz Adjuster. Fiduciary order sealed.'
                              : 'ADJUDICATED: PAYOUT APPROVED FOR SETTLEMENT (\$18,500.00). Check authorized.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDenied ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Standalone Dossier & Cryptographic Assurance Footer Card ──────────────────
class _CryptographicProofCard extends StatelessWidget {
  final ClaimReplayController controller;

  const _CryptographicProofCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifiable Forensic Export Package (RFC 8785 Canonical JSON)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Generates self-contained ZIP dossier containing decision_record.json, forensic_summary_report.txt, and standalone offline verify_chain.py script.',
                        style: TextStyle(fontSize: 11, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: controller.downloadDossier,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export ZIP Dossier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.slate900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
