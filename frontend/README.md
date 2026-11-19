# Lotew Industrial Web Console (`lotew_industrial_web`)

Production-ready Flutter Web frontend for the **Lotew Industrial Evidentiary Decision Assurance Platform**. Designed strictly according to the clean architecture and responsive guidelines referenced in `lotew_dashboard`.

---

## 🏗️ Architecture & Folder Structure

```
lib/
├── core/                               # Cross-cutting foundational modules
│   ├── bindings/
│   │   └── initial_binding.dart        # Global GetX dependency injection (Dio, ResponsiveController)
│   ├── constants/
│   │   ├── app_colors.dart             # Electric Cyan (#00C2FF), Slate 900, Verdict Colors (ACT/WAIT/GET_MORE)
│   │   ├── app_constants.dart          # Tenancy & asset defaults (hydraulic_lab, hydraulic_rig_01)
│   │   ├── app_spacing.dart            # Standard 4/8/16/24/32/48 dp grid
│   │   └── app_text_styles.dart        # Inter for UI, JetBrains Mono for hashes & ms timestamps
│   ├── network/
│   │   ├── api_endpoints.dart          # REST API route constants
│   │   ├── dio_client.dart             # Configured Dio HTTP client with interceptors
│   │   └── network_exception.dart      # Strongly-typed error domain models
│   ├── responsive/
│   │   └── responsive_controller.dart  # Mobile/Tablet/Desktop reactive layout manager
│   ├── router/
│   │   ├── app_pages.dart              # GetPage route definitions
│   │   └── app_routes.dart             # Route paths (/console, /timeline)
│   └── theme/
│       └── app_theme.dart              # Material 3 light/dark theme specification
├── features/
│   ├── evidence_ingestion/             # Core Dual Ingestion Feature
│   │   ├── bindings/
│   │   │   └── evidence_binding.dart
│   │   ├── data/
│   │   │   ├── evidence_repository.dart       # Abstract repository interface
│   │   │   ├── evidence_repository_api.dart   # Live FastAPI backend implementation (Dio)
│   │   │   └── evidence_repository_mock.dart  # Standalone offline mock for demo & unit testing
│   │   ├── domain/
│   │   │   └── models/
│   │   │       ├── canonical_observation_model.dart  # CanonicalObservation v1
│   │   │       └── evidence_item_model.dart          # Evidence row model with ms timestamps
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── evidence_controller.dart          # GetxController for state & upload orchestration
│   │       ├── screens/
│   │       │   └── evidence_console_screen.dart      # Master responsive 2-column console screen
│   │       └── widgets/
│   │           ├── pdf_upload_card.dart              # PDF file picker, metadata inputs & ingest trigger
│   │           ├── telemetry_simulator_card.dart     # Cycle selector (1–2,205), presets & batch trigger
│   │           ├── live_forensic_card.dart           # SHA-256 badge, DB UUID, 3-timestamp ms breakdown
│   │           ├── canonical_json_viewer.dart        # Syntax-styled expandable JSON tree
│   │           └── telemetry_waveform_chart.dart     # fl_chart multi-rate 60s waveform curves
│   └── machine_timeline/              # Chronological machine timeline feature
│       └── presentation/
│           └── machine_timeline_screen.dart          # Interleaved documentary & telemetry event feed
└── shared/
    └── widgets/
        ├── app_scaffold.dart           # Responsive layout with drawer and desktop sidebar
        ├── sidebar_nav.dart            # Navigation links with active status indicators
        └── top_bar.dart                # Header with tenant selector & cryptographic ledger badge
```

---

## 🚀 Running the Web App

### 1. Development Mode (Chrome)
```bash
cd lotew_industrial/frontend
flutter run -d chrome
```

### 2. Standalone Offline Mock vs Live Backend
* **Standalone Mock Mode (Default out-of-the-box):**  
  Click the toggle pill at the top right of the console to switch between `MOCK STANDALONE MODE` and `LIVE API (localhost:8000)`.  
  *Mock mode simulates real SHA-256 hashes, millisecond timestamps, and healthy vs degraded telemetry waveforms without requiring a running backend.*
* **Connecting to Live Backend:**  
  Start the FastAPI backend on port `8000`, toggle to `LIVE API`, and your uploads will post directly to `/api/v1/industrial/evidence/upload-pdf` and persist in Supabase.

---

## 🧪 Automated Testing & Static Analysis
```bash
# Static analysis (zero issues):
flutter analyze

# Widget & unit test suite:
flutter test
```
