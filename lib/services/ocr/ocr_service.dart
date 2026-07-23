import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result from scanning a vehicle registration document.
class RegistrationOcrResult {
  final String rawText;
  final String? registration;
  final String? vin;
  final String? brand;
  final String? model;
  final String? fuelType;
  final String? engineSize;
  final String? year;
  final String? owner;
  final String? color;
  final Map<String, String> extraFields;

  const RegistrationOcrResult({
    required this.rawText,
    this.registration,
    this.vin,
    this.brand,
    this.model,
    this.fuelType,
    this.engineSize,
    this.year,
    this.owner,
    this.color,
    this.extraFields = const {},
  });
}

/// Result from scanning a spare part.
class PartOcrResult {
  final String rawText;
  final String? partNumber;
  final String? brand;
  final String? modelNumber;

  const PartOcrResult({
    required this.rawText,
    this.partNumber,
    this.brand,
    this.modelNumber,
  });
}

/// Service that wraps Google ML Kit Text Recognition.
/// Provides methods for both registration and part scanning.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Recognises all text in an image file.
  Future<String> recogniseText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Parses a vehicle registration document image.
  /// Applies heuristics to extract structured fields from raw OCR text.
  Future<RegistrationOcrResult> parseRegistration(String imagePath) async {
    final rawText = await recogniseText(imagePath);
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    String? registration;
    String? vin;
    String? brand;
    String? model;
    String? fuelType;
    String? engineSize;
    String? year;
    String? owner;
    String? color;
    final extra = <String, String>{};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      // ── Registration number ──────────────────────────────────────────────
      // Typical formats: ABC-123, AB12CDE, 12-AB-34
      if (registration == null) {
        final regMatch = RegExp(
          r'\b([A-Z]{2,3}[-\s]?\d{2,4}[-\s]?[A-Z]{0,3}|'
          r'\d{2}[-\s][A-Z]{2}[-\s]\d{2,4}|'
          r'[A-Z]\d{3}[-\s][A-Z]{3})\b',
        ).firstMatch(upper);
        if (regMatch != null) registration = regMatch.group(0);
      }

      // Field-value pairs from label lines (e.g. "VIN: WBANU51009CT")
      if (_containsLabel(upper, ['VIN', 'CHASSIS', 'CHASSIS NUMBER', 'TELAIO', 'NUMERO TELAIO', 'ΠΛΑΙΣΙΟΥ', 'ΠΛΑΙΣΙΟ'])) {
        vin ??= _extractValue(line, lines, i);
      }

      if (_containsLabel(upper, ['BRAND', 'MAKE', 'MARQUE', 'MARCA', 'HERSTELLER', 'D.1', 'ΜΑΡΚΑ'])) {
        brand ??= _normaliseTitle(_extractValue(line, lines, i));
      }

      if (_containsLabel(upper, ['MODEL', 'MODELE', 'MODELLO', 'D.3', 'ΜΟΝΤΕΛΟ', 'ΤΥΠΟΣ'])) {
        model ??= _extractValue(line, lines, i);
      }

      if (_containsLabel(upper, ['FUEL', 'CARBURANT', 'COMBUSTIBILE', 'P.3', 'ΚΑΥΣΙΜΟ'])) {
        fuelType ??= _extractValue(line, lines, i);
        // Map to standard names
        fuelType = _normaliseFuelType(fuelType);
      }

      if (_containsLabel(upper, ['ENGINE', 'CYLINDREE', 'CILINDRATA', 'P.1', 'ΚΥΒΙΣΜΟΣ'])) {
        engineSize ??= _extractValue(line, lines, i);
      }

      if (_containsLabel(upper, ['YEAR', 'ANNEE', 'ANNO', 'DATE', 'FIRST REGISTRATION', 'ΠΡΩΤΗΣ ΚΥΚΛΟΦΟΡΙΑΣ'])) {
        year ??= _extractYear(line);
        year ??= (i + 1 < lines.length) ? _extractYear(lines[i + 1]) : null;
      }

      if (_containsLabel(upper, ['OWNER', 'PROPRIETAIRE', 'PROPRIETARIO', 'HOLDER', 'C.1', 'C.2', 'ΙΔΙΟΚΤΗΤΗΣ', 'ΚΑΤΟΧΟΣ'])) {
        owner ??= _extractValue(line, lines, i);
      }

      if (_containsLabel(upper, ['COLOR', 'COLOUR', 'COLORE', 'COULEUR', 'ΧΡΩΜΑ'])) {
        color ??= _normaliseColour(_extractValue(line, lines, i));
      }

      // ── VIN standalone on its own line ───────────────────────────────────
      // VINs are 17-char alphanumeric strings
      if (vin == null) {
        final vinMatch = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b').firstMatch(upper);
        if (vinMatch != null) vin = vinMatch.group(0);
      }

      // ── Year standalone ──────────────────────────────────────────────────
      if (year == null) {
        final yearMatch = RegExp(r'\b(19[6-9]\d|20[0-2]\d)\b').firstMatch(line);
        if (yearMatch != null) year = yearMatch.group(0);
      }
    }

    // If no structured registration was found, try a more lenient search
    if (registration == null) {
      final regMatch = RegExp(r'\b[A-Z0-9]{5,10}\b').firstMatch(rawText.toUpperCase());
      registration = regMatch?.group(0);
    }

    return RegistrationOcrResult(
      rawText: rawText,
      registration: registration,
      vin: vin,
      brand: brand,
      model: model,
      fuelType: fuelType,
      engineSize: engineSize,
      year: year,
      owner: owner,
      color: color,
      extraFields: extra,
    );
  }

  /// Parses a spare part image for part number, brand, and model number.
  Future<PartOcrResult> parsePart(String imagePath) async {
    final rawText = await recogniseText(imagePath);
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    String? partNumber;
    String? brand;
    String? modelNumber;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      // Part number: typically "REF:", "OEM:", "PART NO:", etc.
      if (partNumber == null &&
          _containsLabel(upper, ['REF', 'OEM', 'PART NO', 'PART#', 'ARTICLE', 'ART'])) {
        partNumber = _extractValue(line, lines, i);
      }

      // Brand: "BRAND:", "BY:", or just a known brand name
      if (brand == null &&
          _containsLabel(upper, ['BRAND', 'BY', 'MADE BY', 'MANUFACTURER'])) {
        brand = _extractValue(line, lines, i);
      }

      // Model number: patterns like "MOD:", "MODEL:", or alphanumeric codes
      if (modelNumber == null &&
          _containsLabel(upper, ['MODEL', 'MOD', 'TYPE'])) {
        modelNumber = _extractValue(line, lines, i);
      }

      // Fallback: look for standalone part-number-like codes
      if (partNumber == null) {
        final pnMatch = RegExp(
          r'\b([A-Z]{1,5}[-]?\d{3,12}[-]?[A-Z0-9]{0,6})\b',
        ).firstMatch(upper);
        if (pnMatch != null) partNumber = pnMatch.group(0);
      }
    }

    return PartOcrResult(
      rawText: rawText,
      partNumber: partNumber,
      brand: brand,
      modelNumber: modelNumber,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  bool _containsLabel(String upperLine, List<String> labels) {
    return labels.any((label) => upperLine.contains(label));
  }

  /// Extracts the value part of a "Label: Value" line,
  /// or falls back to the next line.
  String? _extractValue(
    String line,
    List<String> lines,
    int index,
  ) {
    // Try "Label: Value" or "Label - Value" format
    final colonIdx = line.indexOf(':');
    final dashIdx = line.indexOf(' - ');

    String? value;
    if (colonIdx != -1 && colonIdx < line.length - 1) {
      value = line.substring(colonIdx + 1).trim();
    } else if (dashIdx != -1) {
      value = line.substring(dashIdx + 3).trim();
    }

    // If no inline value, try the next line
    if ((value == null || value.isEmpty) && index + 1 < lines.length) {
      final next = lines[index + 1].trim();
      if (next.isNotEmpty && !next.toUpperCase().contains(':')) {
        value = next;
      }
    }

    return (value != null && value.isNotEmpty) ? value : null;
  }

  String? _extractYear(String line) {
    final match = RegExp(r'\b(19[6-9]\d|20[0-2]\d)\b').firstMatch(line);
    return match?.group(0);
  }

  String? _normaliseFuelType(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    if (upper.contains('DIESEL') || upper.contains('GASOIL') ||
        upper.contains('ΠΕΤΡΕΛ') || upper.contains('ΠΕΤΡΕΛΑΙΟ')) {
      return 'Diesel';
    }
    if (upper.contains('PETROL') || upper.contains('ESSENCE') ||
        upper.contains('BENZIN') || upper.contains('GASOLINE') ||
        upper.contains('ΒΕΝΖ') || upper.contains('ΒΕΝΖΙΝ')) {
      return 'Petrol';
    }
    if (upper.contains('ELECTR') || upper.contains('ΗΛΕΚΤΡ')) return 'Electric';
    if (upper.contains('HYBRID') || upper.contains('ΥΒΡΙΔ')) return 'Hybrid';
    if (upper.contains('LPG') || upper.contains('GPL') || upper.contains('ΥΓΡΑΕΡ')) return 'LPG';
    if (upper.contains('CNG') || upper.contains('GNC') || upper.contains('ΦΥΣΙΚ')) return 'CNG';
    return raw;
  }

  String? _normaliseColour(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    const colours = {
      'ΜΠΛΕ': 'Blue',
      'BLUE': 'Blue',
      'ΛΕΥΚ': 'White',
      'WHITE': 'White',
      'ΜΑΥΡ': 'Black',
      'BLACK': 'Black',
      'ΚΟΚΚΙΝ': 'Red',
      'RED': 'Red',
      'ΑΣΗΜ': 'Silver',
      'SILVER': 'Silver',
      'ΓΚΡΙ': 'Grey',
      'GRAY': 'Grey',
      'GREY': 'Grey',
      'ΠΡΑΣ': 'Green',
      'GREEN': 'Green',
      'ΚΙΤΡΙΝ': 'Yellow',
      'YELLOW': 'Yellow',
    };
    for (final entry in colours.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return _normaliseTitle(raw);
  }

  String? _normaliseTitle(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;
    return text
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Call this when the service is no longer needed.
  Future<void> dispose() async {
    await _recognizer.close();
  }
}
