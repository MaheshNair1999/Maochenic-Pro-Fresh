/// Global constants used throughout the app.
class AppConstants {
  AppConstants._();

  // ── Database ─────────────────────────────────────────────────────────────
  static const String dbName = 'mechpro.db';
  static const int dbVersion = 2;

  // Table names
  static const String tableVehicles = 'vehicles';
  static const String tableInventory = 'inventory';
  static const String tableJobs = 'jobs';
  static const String tableJobParts = 'job_parts';

  // ── AI ───────────────────────────────────────────────────────────────────
  /// Load the Gemini API key at build time via --dart-define.
  /// Example: flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiApiKeyPrefKey = 'gemini_api_key';
  static const String geminiModel = 'gemini-3.5-flash';
  // Tried in order against the stable v1 API. First success wins.
  // Order matches what this API key has rate limits for (visible in AI Studio).
  static const List<String> geminiVisionModelFallbacks = [
    'gemini-3.5-flash',
    'gemini-3.5-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  // ── Image ────────────────────────────────────────────────────────────────
  static const double imageQuality = 85;
  static const int maxImageDimension = 1024;

  // ── UI ───────────────────────────────────────────────────────────────────
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 16.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimation = Duration(milliseconds: 150);

  // ── Part categories ──────────────────────────────────────────────────────
  static const List<String> partCategories = [
    'Oil Filter',
    'Air Filter',
    'Cabin Filter',
    'Fuel Filter',
    'Spark Plug',
    'Brake Pads',
    'Brake Disc',
    'Battery',
    'Drive Belt',
    'Timing Belt',
    'Water Pump',
    'Alternator',
    'Headlight Bulb',
    'Wiper Blade',
    'Coolant',
    'Engine Oil',
    'Transmission Fluid',
    'Brake Fluid',
    'Power Steering Fluid',
    'Thermostat',
    'Radiator',
    'Starter Motor',
    'Fuel Pump',
    'Oxygen Sensor',
    'Mass Air Flow Sensor',
    'Other',
  ];

  // ── Fuel types ────────────────────────────────────────────────────────────
  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'LPG',
    'CNG',
  ];

  // ── Sort options ──────────────────────────────────────────────────────────
  static const List<String> inventorySortOptions = [
    'Name A–Z',
    'Name Z–A',
    'Brand',
    'Quantity (High)',
    'Quantity (Low)',
    'Date Added',
  ];
}
