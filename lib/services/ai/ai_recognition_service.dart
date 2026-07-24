import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/vehicle_context.dart';
import '../ocr/ocr_service.dart';

/// Result from AI-powered part recognition.
class PartRecognitionResult {
  final String partName;
  final String? partNameGr;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? brand;
  final String? partNumber;
  final String? oemNumber;
  final String? category;
  final String? description;
  final String? descriptionGr;
  final String? compatibility;
  final double confidence;
  final List<String> alternativeNames;

  const PartRecognitionResult({
    required this.partName,
    this.partNameGr,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.brand,
    this.partNumber,
    this.oemNumber,
    this.category,
    this.description,
    this.descriptionGr,
    this.compatibility,
    this.confidence = 0.0,
    this.alternativeNames = const [],
  });
}

/// Final structured vehicle result produced by Gemini from image + OCR text.
class RegistrationExtractionResult {
  final String rawText;
  final String? registration;
  final String? vin;
  final String? chassisNumber;
  final String? make;
  final String? model;
  final String? commercialModel;
  final String? year;
  final String? firstRegistrationDate;
  final String? fuelType;
  final String? engineCapacity;
  final String? engineCode;
  final String? horsepower;
  final String? colour;
  final String? vehicleCategory;
  final String? grossWeight;
  final String? seats;
  final String? owner;
  final String? address;
  final String? registrationAuthority;
  final String? country;
  final String? plateNumber;
  final Map<String, String> extraFields;

  const RegistrationExtractionResult({
    required this.rawText,
    this.registration,
    this.vin,
    this.chassisNumber,
    this.make,
    this.model,
    this.commercialModel,
    this.year,
    this.firstRegistrationDate,
    this.fuelType,
    this.engineCapacity,
    this.engineCode,
    this.horsepower,
    this.colour,
    this.vehicleCategory,
    this.grossWeight,
    this.seats,
    this.owner,
    this.address,
    this.registrationAuthority,
    this.country,
    this.plateNumber,
    this.extraFields = const {},
  });

  factory RegistrationExtractionResult.fromOcr(RegistrationOcrResult ocr) {
    return RegistrationExtractionResult(
      rawText: ocr.rawText,
      registration: ocr.registration,
      vin: ocr.vin,
      make: ocr.brand,
      model: ocr.model,
      year: ocr.year,
      fuelType: ocr.fuelType,
      engineCapacity: ocr.engineSize,
      owner: ocr.owner,
      colour: ocr.color,
      extraFields: ocr.extraFields,
    );
  }

  RegistrationExtractionResult withAiError(String message) {
    return RegistrationExtractionResult(
      rawText: rawText,
      registration: registration,
      vin: vin,
      chassisNumber: chassisNumber,
      make: make,
      model: model,
      commercialModel: commercialModel,
      year: year,
      firstRegistrationDate: firstRegistrationDate,
      fuelType: fuelType,
      engineCapacity: engineCapacity,
      engineCode: engineCode,
      horsepower: horsepower,
      colour: colour,
      vehicleCategory: vehicleCategory,
      grossWeight: grossWeight,
      seats: seats,
      owner: owner,
      address: address,
      registrationAuthority: registrationAuthority,
      country: country,
      plateNumber: plateNumber,
      extraFields: {
        ...extraFields,
        'aiExtractionError': message,
      },
    );
  }
}

/// Service that uses Gemini Vision to identify car parts from photos.
class AiRecognitionService {
  /// Resolves the active Gemini key from local settings first, then build-time.
  Future<String> _resolveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.geminiApiKeyPrefKey)?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return AppConstants.geminiApiKey.trim();
  }

  /// Identifies a car part from an image file.
  /// Returns a [PartRecognitionResult] with the part name and metadata.
  Future<RegistrationExtractionResult> extractRegistration({
    required String imagePath,
    required RegistrationOcrResult ocrResult,
  }) async {
    final apiKey = await _resolveApiKey();
    if (apiKey.isEmpty) {
      return RegistrationExtractionResult.fromOcr(ocrResult).withAiError(
        'Gemini API key is not configured.',
      );
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final prompt = _registrationPrompt(ocrResult.rawText);
      final response = await _generateVisionContent(
        apiKey: apiKey,
        prompt: prompt,
        imagePath: imagePath,
        imageBytes: imageBytes,
        maxOutputTokens: 8192,
      );

      final rawText = response.text ?? '';
      final json = _decodeJsonObject(rawText);
      if (json == null) {
        return RegistrationExtractionResult.fromOcr(ocrResult).withAiError(
          rawText.isEmpty
              ? 'Gemini returned an empty response. Review OCR fields below.'
              : 'AI could not structure the response. OCR fields shown below — check and correct them.',
        );
      }
      return _registrationFromJson(json, ocrResult);
    } on GenerativeAIException catch (e) {
      final msg = _isQuotaExceeded(e)
          ? 'API rate limit reached (2 scans/min on your key). Wait 30–60 s and try again. OCR fields shown below.'
          : e.message.toLowerCase().contains('not found') ||
                  e.message.toLowerCase().contains('not supported')
              ? 'This Gemini model is not available on your API key. Check your key permissions in Settings.'
              : 'Gemini error: ${e.message}. OCR fields shown below.';
      return RegistrationExtractionResult.fromOcr(ocrResult).withAiError(msg);
    } catch (e) {
      return RegistrationExtractionResult.fromOcr(ocrResult).withAiError(
        'Gemini extraction failed. OCR fields shown below — check and correct them.',
      );
    }
  }

  Future<PartRecognitionResult> identifyPart(
    String imagePath, {
    VehicleContext? vehicleContext,
    String? ocrText,
  }) async {
    final apiKey = await _resolveApiKey();
    if (apiKey.isEmpty) {
      return _fallbackIdentification(imagePath);
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final prompt = _partPrompt(
        vehicleContext: vehicleContext,
        ocrText: ocrText,
      );
      final response = await _generateVisionContent(
        apiKey: apiKey,
        prompt: prompt,
        imagePath: imagePath,
        imageBytes: imageBytes,
        maxOutputTokens: 900,
      );

      return _parseGeminiResponse(response.text ?? '', vehicleContext);
    } on GenerativeAIException catch (e) {
      if (_isQuotaExceeded(e)) {
        return const PartRecognitionResult(
          partName: 'Scanned Part',
          category: 'Other',
          description:
              'API rate limit reached (2 scans/min). Wait 30–60 s and try again. OCR data shown below.',
          confidence: 0.0,
        );
      }

      // Handle API errors gracefully
      return PartRecognitionResult(
        partName: 'Unrecognised Part',
        description: 'AI service error: ${e.message}',
        confidence: 0.0,
      );
    } catch (e) {
      return const PartRecognitionResult(
        partName: 'Unrecognised Part',
        description: 'Recognition failed. Please enter details manually.',
        confidence: 0.0,
      );
    }
  }

  Future<GenerateContentResponse> _generateVisionContent({
    required String apiKey,
    required String prompt,
    required String imagePath,
    required Uint8List imageBytes,
    required int maxOutputTokens,
  }) async {
    Object? lastError;
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(_mimeTypeFor(imagePath), imageBytes),
      ]),
    ];

    for (final modelName in AppConstants.geminiVisionModelFallbacks) {
      try {
        final model = _buildModel(
          apiKey,
          modelName: modelName,
          maxOutputTokens: maxOutputTokens,
        );
        return await model.generateContent(content);
      } on GenerativeAIException catch (e) {
        // Quota exhausted — all models share the same key quota, no point
        // trying the remaining fallbacks (and we'd corrupt the error message).
        if (_isQuotaExceeded(e)) throw e;
        lastError = e;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError('No Gemini vision model responded.');
  }

  GenerativeModel _buildModel(
    String apiKey, {
    required String modelName,
    required int maxOutputTokens,
  }) {
    // Use the stable v1 API — v1beta (the SDK default) does not expose
    // gemini-2.0-flash or newer models reliably.
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: maxOutputTokens,
      ),
    );
  }

  String _registrationPrompt(String ocrText) {
    return '''
You are an experienced automotive registration document extraction specialist for Greek and European vehicle certificates.

Use BOTH sources: the original image and this ML Kit OCR text. The OCR may contain Greek mistakes, missing accents, broken columns, rotation errors, or mixed Greek/English text. The image is the source of truth and the OCR is only assistance.

Recognize Greek labels including: Αριθμός Κυκλοφορίας, Αριθμός Πλαισίου, Μάρκα, Τύπος, Μοντέλο, Καύσιμο, Κυβισμός, Ιδιοκτήτης, Χρώμα, Κατηγορία, Θέσεις, Μικτό Βάρος, Έτος Πρώτης Κυκλοφορίας.

Normalize values to English. Examples: Βενζίνη -> Petrol, Πετρέλαιο -> Diesel, ΜΠΛΕ -> Blue, FIAT -> Fiat. If a field cannot be determined confidently, use an empty string. Do not hallucinate.

Start your response immediately with { and output ONLY valid JSON, no markdown, no preamble, no explanation:
{"registrationNumber":"","vin":"","chassisNumber":"","make":"","model":"","commercialModel":"","year":"","firstRegistrationDate":"","fuelType":"","engineCapacity":"","engineCode":"","horsepower":"","colour":"","vehicleCategory":"","grossWeight":"","seats":"","owner":"","address":"","registrationAuthority":"","country":"","plateNumber":"","additionalFields":{}}

OCR text:
${jsonEncode(ocrText)}
''';
  }

  String _partPrompt({VehicleContext? vehicleContext, String? ocrText}) {
    return '''
You are an experienced automotive technician identifying spare parts for a real workshop. Analyze dirty, rusty, worn, broken, oily, partially hidden, low-light, close-up, and angled part photos.

Use the image first. Recognize common automotive parts even when there is no readable text: spark plugs, filters, brake pads, brake discs, belts, batteries, bulbs, pumps, alternators, sensors, fluids, hoses, bearings, wipers, and similar workshop parts.

Use visible markings and OCR text only as supporting evidence. If a manufacturer, part number, or OEM number is visible, read it. If compatibility is obvious, return it. Use vehicle context automatically when present.

Provide "partName" and "description" in English, and "partNameGr" and "descriptionGr" as their Greek translations (e.g. Oil Filter -> Φίλτρο Λαδιού). Keep descriptions short (1-2 sentences).

Vehicle context:
${jsonEncode(vehicleContext?.toJson() ?? <String, dynamic>{})}

OCR text:
${jsonEncode(ocrText ?? '')}

Return ONLY valid JSON, no markdown, no explanation:
{
  "partName":"",
  "partNameGr":"",
  "vehicleMake":"",
  "vehicleModel":"",
  "vehicleYear":"",
  "brand":"",
  "partNumber":"",
  "oemNumber":"",
  "category":"",
  "description":"",
  "descriptionGr":"",
  "compatibility":"",
  "confidence":0.0,
  "alternativeNames":[]
}

If the object is clearly an automotive part but the exact variant is uncertain, still return the generic part name with a moderate confidence. Use "Unknown Part" only when the image does not contain an identifiable automotive part.
''';
  }

  RegistrationExtractionResult _registrationFromJson(
    Map<String, dynamic> json,
    RegistrationOcrResult ocr,
  ) {
    final extra = <String, String>{...ocr.extraFields};
    final additional = json['additionalFields'];
    if (additional is Map) {
      additional.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          extra[key.toString()] = value.toString().trim();
        }
      });
    }

    void addExtra(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) extra[key] = value.trim();
    }

    final chassisNumber = _jsonString(json, 'chassisNumber');
    final commercialModel = _jsonString(json, 'commercialModel');
    final firstRegistrationDate = _jsonString(json, 'firstRegistrationDate');
    final engineCode = _jsonString(json, 'engineCode');
    final horsepower = _jsonString(json, 'horsepower');
    final vehicleCategory = _jsonString(json, 'vehicleCategory');
    final grossWeight = _jsonString(json, 'grossWeight');
    final seats = _jsonString(json, 'seats');
    final address = _jsonString(json, 'address');
    final registrationAuthority = _jsonString(json, 'registrationAuthority');
    final country = _jsonString(json, 'country');
    final plateNumber = _jsonString(json, 'plateNumber');

    addExtra('chassisNumber', chassisNumber);
    addExtra('commercialModel', commercialModel);
    addExtra('firstRegistrationDate', firstRegistrationDate);
    addExtra('engineCode', engineCode);
    addExtra('horsepower', horsepower);
    addExtra('vehicleCategory', vehicleCategory);
    addExtra('grossWeight', grossWeight);
    addExtra('seats', seats);
    addExtra('address', address);
    addExtra('registrationAuthority', registrationAuthority);
    addExtra('country', country);
    addExtra('plateNumber', plateNumber);

    return RegistrationExtractionResult(
      rawText: ocr.rawText,
      registration:
          _prefer(_jsonString(json, 'registrationNumber'), ocr.registration),
      vin: _prefer(_jsonString(json, 'vin'), ocr.vin),
      chassisNumber: chassisNumber,
      make: _prefer(_jsonString(json, 'make'), ocr.brand),
      model: _prefer(_jsonString(json, 'model'), ocr.model),
      commercialModel: commercialModel,
      year: _prefer(_jsonString(json, 'year'), ocr.year),
      firstRegistrationDate: firstRegistrationDate,
      fuelType: _prefer(_jsonString(json, 'fuelType'), ocr.fuelType),
      engineCapacity:
          _prefer(_jsonString(json, 'engineCapacity'), ocr.engineSize),
      engineCode: engineCode,
      horsepower: horsepower,
      colour: _prefer(_jsonString(json, 'colour'), ocr.color),
      vehicleCategory: vehicleCategory,
      grossWeight: grossWeight,
      seats: seats,
      owner: _prefer(_jsonString(json, 'owner'), ocr.owner),
      address: address,
      registrationAuthority: registrationAuthority,
      country: country,
      plateNumber: plateNumber,
      extraFields: extra,
    );
  }

  PartRecognitionResult _parseGeminiResponse(
    String text,
    VehicleContext? vehicleContext,
  ) {
    try {
      final json = _decodeJsonObject(text);
      if (json == null) return _unknownResult();

      return PartRecognitionResult(
        partName: _jsonString(json, 'partName') ?? 'Unknown Part',
        partNameGr: _jsonString(json, 'partNameGr'),
        vehicleMake:
            _prefer(_jsonString(json, 'vehicleMake'), vehicleContext?.make),
        vehicleModel:
            _prefer(_jsonString(json, 'vehicleModel'), vehicleContext?.model),
        vehicleYear:
            _prefer(_jsonString(json, 'vehicleYear'), vehicleContext?.year),
        brand: _jsonString(json, 'brand'),
        partNumber: _jsonString(json, 'partNumber'),
        oemNumber: _jsonString(json, 'oemNumber'),
        category: _jsonString(json, 'category'),
        description: _jsonString(json, 'description'),
        descriptionGr: _jsonString(json, 'descriptionGr'),
        compatibility: _prefer(
          _jsonString(json, 'compatibility'),
          vehicleContext?.displayName,
        ),
        confidence: _jsonDouble(json, 'confidence') ?? 0.0,
        alternativeNames: _jsonStringList(json, 'alternativeNames'),
      );
    } catch (_) {
      return _unknownResult();
    }
  }

  /// Robustly extracts a JSON object from Gemini output.
  ///
  /// Handles:
  ///   • Thinking-model output  (<think>…</think> / <thinking>…</thinking>)
  ///   • Markdown code fences   (```json … ```)
  ///   • Raw JSON embedded in surrounding prose
  ///   • Trailing commas in JSON (Gemini sometimes outputs them)
  ///
  /// Returns the **last** valid top-level JSON object found (the actual answer
  /// appears after any chain-of-thought reasoning).
  Map<String, dynamic>? _decodeJsonObject(String text) {
    // ── 1. Strip thinking blocks ──────────────────────────────────────────────
    String cleaned = text
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<thought>[\s\S]*?</thought>', caseSensitive: false), '')
        .trim();

    // ── 2. Extract from markdown code fence if present ────────────────────────
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(cleaned);
    if (fence != null) {
      final candidate = fence.group(1)?.trim() ?? '';
      final result = _tryParseJson(candidate);
      if (result != null) return result;
    }

    // ── 3. Walk the string and collect every balanced { … } block ────────────
    // Return the LAST one that parses as a JSON object (after any preamble).
    Map<String, dynamic>? lastValid;
    int depth = 0;
    int? blockStart;

    for (int i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      // Skip characters inside string literals to avoid false braces
      if (ch == '"') {
        i++;
        while (i < cleaned.length) {
          if (cleaned[i] == '\\') { i += 2; continue; }
          if (cleaned[i] == '"') break;
          i++;
        }
        continue;
      }
      if (ch == '{') {
        if (depth == 0) blockStart = i;
        depth++;
      } else if (ch == '}') {
        if (depth > 0) depth--;
        if (depth == 0 && blockStart != null) {
          final candidate = cleaned.substring(blockStart, i + 1);
          final result = _tryParseJson(candidate);
          if (result != null) lastValid = result;
          blockStart = null;
        }
      }
    }

    if (lastValid != null) return lastValid;

    // ── 4. No complete {} found — wrap first key-value block in braces ────────
    // Gemini 3.5 Flash thinking models often emit JSON body without enclosing {}.
    // Find where the first JSON key starts and try wrapping to end of string.
    final kvMatch = RegExp(r'"[A-Za-z][^"]*"\s*:').firstMatch(cleaned);
    if (kvMatch != null) {
      final body = cleaned.substring(kvMatch.start).trimRight();
      // Strip trailing comma if present
      final trimmed = body.endsWith(',') ? body.substring(0, body.length - 1) : body;
      final r4 = _tryParseJson('{$trimmed}');
      if (r4 != null) return r4;
      // Also try up to the last closing quote or value
      final lastBrace = body.lastIndexOf('}');
      if (lastBrace > 0) {
        final r4b = _tryParseJson('{${body.substring(0, lastBrace + 1)}}');
        if (r4b != null) return r4b;
      }
    }

    // ── 5. Regex field extraction — last resort ───────────────────────────────
    // Picks "key": "value" / number / boolean from anywhere in the text.
    return _extractFieldsByRegex(cleaned);
  }

  /// Tries to parse [candidate] as a JSON object, with automatic sanitisation
  /// for common Gemini formatting quirks (trailing commas, JS-style comments).
  Map<String, dynamic>? _tryParseJson(String candidate) {
    // First attempt: strict parse
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    // Second attempt: strip trailing commas before } or ]
    // Gemini (especially thinking models) frequently outputs them.
    try {
      final sanitized = candidate.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');
      final decoded = jsonDecode(sanitized);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    // Third attempt: also strip // line comments (rare but possible)
    try {
      final noComments = candidate
          .replaceAll(RegExp(r'//[^\n]*'), '')
          .replaceAll(RegExp(r',(\s*[}\]])'), r'$1');
      final decoded = jsonDecode(noComments);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    return null;
  }

  /// Extracts "key": value pairs from anywhere in [text] using regex.
  /// Used when no complete JSON object can be located in the model response.
  /// Always takes the LAST occurrence of each key so the final answer
  /// (which appears after thinking content) wins.
  Map<String, dynamic>? _extractFieldsByRegex(String text) {
    final map = <String, dynamic>{};

    // String values: "key": "value"  — overwrites earlier occurrences
    final strRe = RegExp(r'"([A-Za-z][A-Za-z0-9_]*)"\s*:\s*"((?:[^"\\]|\\.)*)"');
    for (final m in strRe.allMatches(text)) {
      map[m.group(1)!] = m.group(2) ?? '';
    }

    // Numeric values: "key": 1234 or "key": 1.5  — only if not already a string
    final numRe = RegExp(r'"([A-Za-z][A-Za-z0-9_]*)"\s*:\s*(-?\d+\.?\d*)');
    for (final m in numRe.allMatches(text)) {
      final key = m.group(1)!;
      if (map[key] is! String) map[key] = num.tryParse(m.group(2)!) ?? 0;
    }

    // Boolean values: "key": true/false  — only if not already a string
    final boolRe = RegExp(r'"([A-Za-z][A-Za-z0-9_]*)"\s*:\s*(true|false)');
    for (final m in boolRe.allMatches(text)) {
      final key = m.group(1)!;
      if (map[key] is! String) map[key] = m.group(2) == 'true';
    }

    return map.isEmpty ? null : map;
  }

  String? _jsonString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  double? _jsonDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse(value.toString());
  }

  List<String> _jsonStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _prefer(String? primary, String? fallback) {
    return primary != null && primary.trim().isNotEmpty ? primary : fallback;
  }

  String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  PartRecognitionResult _unknownResult() {
    return const PartRecognitionResult(
      partName: 'Unknown Part',
      category: 'Other',
      description: 'Could not identify the part. Please enter details manually.',
      confidence: 0.0,
    );
  }

  bool _isQuotaExceeded(GenerativeAIException error) {
    final message = error.message.toLowerCase();
    return message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('429') ||
        message.contains('exceeded your current quota');
  }

  /// Fallback when API key is not configured — uses heuristics from OCR text.
  Future<PartRecognitionResult> _fallbackIdentification(String imagePath) async {
    return const PartRecognitionResult(
      partName: 'Scanned Part',
      category: 'Other',
      description: 'AI recognition not configured. Add your Gemini API key in Settings to enable it.',
      confidence: 0.0,
    );
  }
}
