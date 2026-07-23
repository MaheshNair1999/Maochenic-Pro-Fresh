import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../services/ai/ai_recognition_service.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../camera/camera_capture_page.dart';

/// Page where the mechanic scans a vehicle registration document.
/// Shows camera → OCR → editable form → save.
class ScanRegistrationPage extends ConsumerStatefulWidget {
  const ScanRegistrationPage({super.key});

  @override
  ConsumerState<ScanRegistrationPage> createState() =>
      _ScanRegistrationPageState();
}

class _ScanRegistrationPageState extends ConsumerState<ScanRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _ocr = OcrService();
  final _ai = AiRecognitionService();

  // Form controllers
  final _regCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  String? _imagePath;
  Map<String, String> _extraFields = const {};
  String? _aiExtractionError;
  bool _isScanning = false;
  bool _isSaving = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _ocr.dispose();
    _regCtrl.dispose();
    _vinCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _fuelCtrl.dispose();
    _engineCtrl.dispose();
    _yearCtrl.dispose();
    _ownerCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  // ── Camera & OCR ──────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    final filePath = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(
          mode: CameraCaptureMode.registration,
          title: 'Scan Registration Document',
        ),
        fullscreenDialog: true,
      ),
    );

    if (filePath == null) return;
    setState(() {
      _imagePath = filePath;
      _isScanning = true;
      _hasScanned = false;
    });

    await _runOcr(filePath);
  }

  Future<void> _runOcr(String filePath) async {
    try {
      final processedPath = await ImageUtils.prepareForAi(filePath);
      _imagePath = processedPath;
      String? ocrWarning;
      RegistrationOcrResult ocrResult;

      try {
        ocrResult = await _ocr.parseRegistration(processedPath);
      } catch (_) {
        ocrWarning =
            'Local OCR could not read this image. Gemini used the photo directly; review the fields before saving.';
        ocrResult = const RegistrationOcrResult(rawText: '');
      }

      final result = await _ai.extractRegistration(
        imagePath: processedPath,
        ocrResult: ocrResult,
      );

      setState(() {
        _isScanning = false;
        _hasScanned = true;
        _extraFields = result.extraFields;
        final aiError = result.extraFields['aiExtractionError'];
        _aiExtractionError = [
          if (ocrWarning != null) ocrWarning,
          if (aiError != null) aiError,
        ].join('\n\n');
        if (_aiExtractionError!.isEmpty) _aiExtractionError = null;

        // Populate fields only if not already filled by user
        if (result.registration != null) _regCtrl.text = result.registration!;
        if (result.vin != null) _vinCtrl.text = result.vin!;
        if (result.make != null) _brandCtrl.text = result.make!;
        if (result.model != null) _modelCtrl.text = result.model!;
        if (result.fuelType != null) _fuelCtrl.text = result.fuelType!;
        if (result.engineCapacity != null) {
          _engineCtrl.text = result.engineCapacity!;
        }
        if (result.year != null) _yearCtrl.text = result.year!;
        if (result.owner != null) _ownerCtrl.text = result.owner!;
        if (result.colour != null) _colorCtrl.text = result.colour!;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _hasScanned = true;
        _extraFields = const {};
        _aiExtractionError =
            'Automatic recognition failed. You can still enter the vehicle details manually.';
      });
      if (mounted) {
        showErrorSnackbar(
            context, 'Automatic recognition failed. Enter details manually.');
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        registration: _regCtrl.text.trim(),
        vin: _vinCtrl.text.trim().isNotEmpty ? _vinCtrl.text.trim() : null,
        brand:
            _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
        model:
            _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : null,
        fuelType:
            _fuelCtrl.text.trim().isNotEmpty ? _fuelCtrl.text.trim() : null,
        engineSize:
            _engineCtrl.text.trim().isNotEmpty ? _engineCtrl.text.trim() : null,
        year: _yearCtrl.text.trim().isNotEmpty ? _yearCtrl.text.trim() : null,
        owner:
            _ownerCtrl.text.trim().isNotEmpty ? _ownerCtrl.text.trim() : null,
        color:
            _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
        extraFields: _extraFields,
        imagePath: _imagePath,
        createdAt: now,
        updatedAt: now,
      );

      final id =
          await ref.read(vehicleListProvider.notifier).addVehicle(vehicle);

      if (mounted) {
        showSuccessSnackbar(context, 'Vehicle saved successfully!');
        context.pop();
        context.push('${AppRoutes.vehicles}/$id');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showErrorSnackbar(context, 'Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Registration'),
        actions: [
          if (_hasScanned)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'SAVE',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scan button / preview ──────────────────────────────────
            _buildScanSection(theme),

            // ── OCR scanning indicator ─────────────────────────────────
            if (_isScanning)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Reading document…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            // ── Form ───────────────────────────────────────────────────
            if (_hasScanned && !_isScanning) ...[
              _buildSuccessBanner(theme),
              if (_aiExtractionError != null) _buildAiWarning(theme),
              _buildForm(theme),
            ],
          ],
        ),
      ),
      floatingActionButton: _hasScanned
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Vehicle'),
            )
          : null,
    );
  }

  Widget _buildScanSection(ThemeData theme) {
    if (_imagePath != null && File(_imagePath!).existsSync()) {
      return Stack(
        children: [
          Image.file(
            File(_imagePath!),
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'rescan',
              onPressed: _openCamera,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _openCamera,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.08, duration: 1200.ms, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            Text(
              'Scan Vehicle Registration',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to open camera and take a photo of the document',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSuccessBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E8449).withValues(alpha: 0.12),
        border:
            Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1E8449)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Document scanned! Review and correct any fields below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1E8449),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildAiWarning(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF39C12).withValues(alpha: 0.12),
        border:
            Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF39C12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _aiExtractionError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Vehicle Details',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Check and edit any incorrect fields',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            LabelledTextField(
              label: 'Registration Number *',
              hint: 'e.g. AB12CDE',
              controller: _regCtrl,
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            LabelledTextField(
              label: 'VIN / Chassis Number',
              hint: '17-character code',
              controller: _vinCtrl,
              prefixIcon: Icons.pin_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LabelledTextField(
                    label: 'Brand',
                    hint: 'e.g. Toyota',
                    controller: _brandCtrl,
                    prefixIcon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabelledTextField(
                    label: 'Model',
                    hint: 'e.g. Corolla',
                    controller: _modelCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FuelDropdown(controller: _fuelCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabelledTextField(
                    label: 'Engine Size',
                    hint: 'e.g. 1.6L / 1598cc',
                    controller: _engineCtrl,
                    prefixIcon: Icons.settings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LabelledTextField(
                    label: 'Year',
                    hint: 'e.g. 2019',
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabelledTextField(
                    label: 'Colour',
                    hint: 'e.g. Silver',
                    controller: _colorCtrl,
                    prefixIcon: Icons.color_lens_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LabelledTextField(
              label: 'Owner / Keeper',
              hint: 'Name on document (optional)',
              controller: _ownerCtrl,
              prefixIcon: Icons.person_outlined,
            ),
            const SizedBox(height: 80),
          ]
              .animate(interval: 60.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }
}

class _FuelDropdown extends StatefulWidget {
  final TextEditingController controller;
  const _FuelDropdown({required this.controller});

  @override
  State<_FuelDropdown> createState() => _FuelDropdownState();
}

class _FuelDropdownState extends State<_FuelDropdown> {
  @override
  Widget build(BuildContext context) {
    final selected =
        widget.controller.text.isNotEmpty ? widget.controller.text : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Type',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue:
              AppConstants.fuelTypes.contains(selected) ? selected : null,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.local_gas_station_outlined),
          ),
          hint: const Text('Select'),
          items: AppConstants.fuelTypes
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              widget.controller.text = v;
              setState(() {});
            }
          },
        ),
      ],
    );
  }
}
