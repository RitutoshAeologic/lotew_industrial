class AppConstants {
  // Backend API URL (Can be overridden via --dart-define=API_URL=...)
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Default Tenancy & Asset
  static const defaultTenantId = 'hydraulic_lab';
  static const defaultTenantName = 'UCI Hydraulic Rig';
  static const defaultAssetId = 'hydraulic_rig_01';

  // Available Tenants (From Image 1)
  static const tenants = [
    {'id': 'hydraulic_lab', 'name': 'UCI Hydraulic Rig'},
    {'id': 'metro_porto', 'name': 'Metro do Porto'},
    {'id': 'scania_fleet', 'name': 'SCANIA Fleet'},
    {'id': 'petrobras_3w', 'name': 'Petrobras 3W'},
  ];

  // Available Components for Hydraulic Rig
  static const hydraulicComponents = [
    {'id': 'cooler', 'name': 'Cooler (Heat Exchanger)'},
    {'id': 'pump', 'name': 'Axial Piston Main Pump'},
    {'id': 'valve', 'name': 'Directional Control Valve'},
    {'id': 'accumulator', 'name': 'Hydraulic Accumulator'},
  ];

  // Permitted Actions
  static const proposedActions = [
    'INSPECT_PUMP_SEAL',
    'SHUTDOWN_PUMP_EMERGENCY',
    'CLEAN_COOLER_HEAT_EXCHANGER',
    'REPLACE_DIRECTIONAL_VALVE',
    'CHECK_ACCUMULATOR_PRECHARGE',
    'CONTINUE_NORMAL_OPERATION',
  ];
}

