import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class CanonicalJsonViewer extends StatefulWidget {
  final Map<String, dynamic> data;

  const CanonicalJsonViewer({super.key, required this.data});

  @override
  State<CanonicalJsonViewer> createState() => _CanonicalJsonViewerState();
}

class _CanonicalJsonViewerState extends State<CanonicalJsonViewer> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(widget.data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Universal CanonicalObservation v1 Payload', style: AppTextStyles.headingSmall),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 18),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      tooltip: _isExpanded ? 'Collapse' : 'Expand',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: formatted));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Canonical JSON copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy JSON',
                    ),
                  ],
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 380),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    formatted,
                    style: AppTextStyles.monoSmall.copyWith(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

