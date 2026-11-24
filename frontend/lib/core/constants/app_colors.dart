import 'package:flutter/material.dart';

class AppColors {
  // --- Brand & Accents ---
  static const primary = Color(0xFF00C2FF); // Electric Cyan
  static const primaryDark = Color(0xFF0088B3);
  static const primaryLight = Color(0xFFE0F7FF);

  // --- Industrial Theme Backgrounds & Surfaces ---
  static const bgLight = Color(0xFFF8FAFC); // Slate 50
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE2E8F0); // Slate 200

  // --- Dark / Technical Accents ---
  static const slate900 = Color(0xFF0F172A); // Header / Sidebar dark
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);

  // --- Text Colors ---
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // --- Evidentiary Headline Verdicts ---
  static const verdictAct = Color(0xFFEF4444); // Red: Sufficient evidence to ACT
  static const verdictWait = Color(0xFF10B981); // Green: Machine healthy / WAIT
  static const verdictEvidence = Color(0xFFF59E0B); // Amber: GET MORE EVIDENCE

  // --- Data & Forensics Semantic Colors ---
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF00C2FF);

  // --- Telemetry Sensor Waveform Colors ---
  static const sensorPressure = Color(0xFF00C2FF); // 100 Hz PS1 (Cyan)
  static const sensorFlow = Color(0xFF10B981); // 10 Hz FS1 (Green)
  static const sensorTemp = Color(0xFFF59E0B); // 1 Hz TS1 (Amber)
  static const sensorPower = Color(0xFF8B5CF6); // 100 Hz EPS1 (Purple)
  static const hashBadgeBg = Color(0xFF1E293B);
  static const hashBadgeText = Color(0xFF38BDF8);
}

