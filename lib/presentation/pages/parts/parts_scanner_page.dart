import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/inventory_model.dart';
import '../../../services/ai/ai_recognition_service.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../camera/camera_capture_page.dart';

/// Page where the mechanic scans spare parts.
/// Runs AI vision + OCR on the photo, then shows an editable form
/// before adding to inventory.
class PartsScannerPage extends ConsumerStatefulWidget {
  const PartsScannerPage({super.key});

  @override
  ConsumerState<PartsScannerPage> createState() => _PartsScannerPageState();
}

class _PartsScannerPageState extends ConsumerState<PartsScannerPage> {
  final _ocr = OcrService();
  final _ai = AiRecognitionService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _partNumCtrl = TextEditingController();
  final _oemCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedCategory;
  String? _compatibility;

  String? _imagePath;
  bool _isProcessing = false;
  bool _hasResult = false;
  bool _isSaving = false;
  String? _aiDescription;
  double _confidence = 0;

  @override
  void dispose() {
    _ocr.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _partNumCtrl.dispose();
    _oemCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    final filePath = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(
          mode: CameraCaptureMode.part,
          title: 'Scan Part',
        ),
        fullscreenDialog: true,
      ),
    );
    if (filePath == null) return;

    setState(() {
      _imagePath = filePath;
      _isProcessing = true;
      _hasResult = false;
    });

    await _processImage(filePath);
  }

  Future<void> _processImage(String filePath) async {
    try {
      final processedPath = await ImageUtils.prepareForAi(filePath);
      _imagePath = processedPath;
      final vehicleContext = ref.read(activeVehicleContextProvider);
      PartOcrResult ocrResult;

      try {
        ocrResult = await _ocr.parsePart(processedPath);
      } catch (_) {
        ocrResult = const PartOcrResult(rawText: '');
      }

      final aiResult = await _ai.identifyPart(
        processedPath,
        vehicleContext: vehicleContext,
        ocrText: ocrResult.rawText,
      );

      setState(() {
        _isProcessing = false;
        _hasResult = true;

        // Prefer AI name; fall back to OCR clues
        _nameCtrl.text =
            aiResult.partName == 'Scanned Part' && ocrResult.modelNumber != null
                ? ocrResult.modelNumber!
                : aiResult.partName;
        _selectedCategory = aiResult.category;
        _aiDescription = aiResult.description;
        _confidence = aiResult.confidence;
        _compatibility = aiResult.compatibility;

        // OCR fills in part number and brand
        if (aiResult.partNumber != null && aiResult.partNumber!.isNotEmpty) {
          _partNumCtrl.text = aiResult.partNumber!;
        } else if (ocrResult.partNumber != null && _partNumCtrl.text.isEmpty) {
          _partNumCtrl.text = ocrResult.partNumber!;
        }
        if (aiResult.brand != null && aiResult.brand!.isNotEmpty) {
          _brandCtrl.text = aiResult.brand!;
        } else if (ocrResult.brand != null && _brandCtrl.text.isEmpty) {
          _brandCtrl.text = ocrResult.brand!;
        }
        if (aiResult.oemNumber != null) _oemCtrl.text = aiResult.oemNumber!;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) showErrorSnackbar(context, 'Processing failed: $e');
    }
  }

  // ── Save to inventory ─────────────────────────────────────────────────────

  Future<void> _addToInventory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final vehicleContext = ref.read(activeVehicleContextProvider);
      final baseName = _nameCtrl.text.trim();
      final vehicleLabel = vehicleContext?.displayName;
      final storedName = vehicleLabel == null ||
              vehicleLabel.isEmpty ||
              baseName.contains(vehicleLabel)
          ? baseName
          : '$baseName\n$vehicleLabel';
      final item = InventoryModel(
        vehicleId: vehicleContext?.vehicleId,
        vehicleMake: vehicleContext?.make,
        vehicleModel: vehicleContext?.model,
        vehicleYear: vehicleContext?.year,
        name: storedName,
        brand:
            _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
        partNumber: _partNumCtrl.text.trim().isNotEmpty
            ? _partNumCtrl.text.trim()
            : null,
        oemNumber:
            _oemCtrl.text.trim().isNotEmpty ? _oemCtrl.text.trim() : null,
        category: _selectedCategory,
        compatibility: _compatibility ?? vehicleLabel,
        notes:
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        confidenceScore: _confidence,
        imagePath: _imagePath,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(inventoryProvider.notifier).addItem(item);

      if (mounted) {
        showSuccessSnackbar(context, 'Added to inventory!');
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showErrorSnackbar(context, 'Save failed: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _imagePath = null;
      _hasResult = false;
      _isProcessing = false;
      _isSaving = false;
      _aiDescription = null;
      _confidence = 0;
      _nameCtrl.clear();
      _brandCtrl.clear();
      _partNumCtrl.clear();
      _oemCtrl.clear();
      _notesCtrl.clear();
      _selectedCategory = null;
      _compatibility = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleContext = ref.watch(activeVehicleContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Part Scanner'),
        actions: [
          if (_hasResult)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetForm,
              tooltip: 'Scan another',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vehicleContext != null)
              _buildVehicleContextBanner(theme, vehicleContext.displayName),
            _buildPhotoSection(theme),
            if (_isProcessing) _buildProcessingIndicator(theme),
            if (_hasResult && !_isProcessing) ...[
              _buildAiResultBanner(theme),
              _buildForm(theme),
            ],
          ],
        ),
      ),
      floatingActionButton: !_hasResult
          ? FloatingActionButton.extended(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Part'),
            ).animate().scale(delay: 500.ms, curve: Curves.elasticOut)
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _addToInventory,
              backgroundColor: const Color(0xFF1E8449),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Inventory'),
            ),
    );
  }

  Widget _buildVehicleContextBanner(ThemeData theme, String vehicleName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              vehicleName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    if (_imagePath != null && File(_imagePath!).existsSync()) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          Image.file(
            File(_imagePath!),
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
          ).animate().fadeIn(duration: 400.ms),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FloatingActionButton.small(
              heroTag: 'rescan_part',
              onPressed: _openCamera,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: _openCamera,
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.08, duration: 1200.ms),
              const SizedBox(height: 20),
              Text(
                'Scan a Spare Part',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI will identify the part automatically',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'OCR will detect part number and brand',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProcessingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Identifying part…', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Running AI recognition + OCR',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAiResultBanner(ThemeData theme) {
    final hasAi = _confidence > 0;
    final isRateLimit = _aiDescription?.contains('rate limit') == true ||
        _aiDescription?.contains('quota') == true;
    final confPct = (_confidence * 100).toStringAsFixed(0);

    final Color bannerColor = hasAi
        ? theme.colorScheme.primary
        : isRateLimit
            ? const Color(0xFFF39C12) // amber for rate limit
            : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            hasAi
                ? Icons.auto_awesome
                : isRateLimit
                    ? Icons.timer_outlined
                    : Icons.qr_code,
            color: bannerColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAi
                      ? 'AI Identified: $confPct% confidence'
                      : isRateLimit
                          ? 'Rate limit — OCR only'
                          : 'OCR extracted text from image',
                  style: theme.textTheme.labelLarge?.copyWith(color: bannerColor),
                ),
                if (_aiDescription != null)
                  Text(
                    _aiDescription!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 400.ms);
  }

  Widget _buildForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Part Details', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Review and edit before adding to inventory',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            _CategoryDropdown(
              selected: _selectedCategory,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),

            LabelledTextField(
              label: 'Part Name *',
              hint: 'e.g. Oil Filter',
              controller: _nameCtrl,
              prefixIcon: Icons.build_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: LabelledTextField(
                    label: 'Brand',
                    hint: 'e.g. Bosch',
                    controller: _brandCtrl,
                    prefixIcon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabelledTextField(
                    label: 'Part Number',
                    hint: 'e.g. W940/25',
                    controller: _partNumCtrl,
                    prefixIcon: Icons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LabelledTextField(
              label: 'OEM Number',
              hint: 'e.g. manufacturer OEM reference',
              controller: _oemCtrl,
              prefixIcon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(height: 12),

            LabelledTextField(
              label: 'Notes',
              hint: 'Any additional information…',
              controller: _notesCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 80),
          ].animate(interval: 50.ms).fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue:
              AppConstants.partCategories.contains(selected) ? selected : null,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
          ),
          hint: const Text('Select category'),
          isExpanded: true,
          items: AppConstants.partCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
