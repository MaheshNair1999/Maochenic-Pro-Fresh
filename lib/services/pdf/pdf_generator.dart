import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/job_model.dart';
import '../../data/models/vehicle_model.dart';

/// Generates a professional job-sheet PDF.
class PdfGenerator {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1B4F72);
  static const PdfColor _accent = PdfColor.fromInt(0xFFF39C12);
  static const PdfColor _light = PdfColor.fromInt(0xFFF5F7FA);
  static const PdfColor _border = PdfColor.fromInt(0xFFDDE1E7);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A1A2E);
  static const PdfColor _textMid = PdfColor.fromInt(0xFF5A6478);

  Future<String> generateJobSheet({
    required JobModel job,
    required VehicleModel vehicle,
  }) async {
    final pdf = pw.Document(
      title: 'Job Sheet - ${vehicle.registration}',
      author: 'maochanicProFresh',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(vehicle, job),
          pw.SizedBox(height: 24),
          _buildVehicleInfo(vehicle),
          pw.SizedBox(height: 16),
          _buildJobInfo(job),
          pw.SizedBox(height: 24),
          _buildPartsTable(job),
          pw.SizedBox(height: 16),
          _buildSummary(job),
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotes(job.notes!),
          ],
          pw.SizedBox(height: 32),
          _buildSignatureArea(),
          pw.SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final filename =
        'job_${job.id}_${vehicle.registration.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildHeader(VehicleModel vehicle, JobModel job) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'maochanicProFresh',
                style: const pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Professional Mechanic Services',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'JOB SHEET',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '#${job.id?.toString().padLeft(6, '0') ?? '000000'}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehicleInfo(VehicleModel vehicle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _light,
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vehicle Information',
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(flex: 1, child: _infoCell('Registration', vehicle.registration)),
              pw.Expanded(flex: 1, child: _infoCell('Brand', vehicle.brand ?? '-')),
              pw.Expanded(flex: 1, child: _infoCell('Model', vehicle.model ?? '-')),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(flex: 1, child: _infoCell('VIN', vehicle.vin ?? '-')),
              pw.Expanded(flex: 1, child: _infoCell('Year', vehicle.year ?? '-')),
              pw.Expanded(flex: 1, child: _infoCell('Fuel', vehicle.fuelType ?? '-')),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildJobInfo(JobModel job) {
    final dateStr = DateFormat('dd MMM yyyy').format(job.date);
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: _infoCell('Customer', job.customer ?? '-'),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: _infoCell('Date', dateStr),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _statusColour(job.status),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: _infoCell('Status', job.status.displayName, valueColor: PdfColors.white),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPartsTable(JobModel job) {
    if (job.parts.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Center(
          child: pw.Text(
            'No parts recorded for this job.',
            style: const pw.TextStyle(color: _textMid, fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Parts Used',
          style: const pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: [
                _tableHeader('Part Name'),
                _tableHeader('Part Number'),
                _tableHeader('Brand'),
                _tableHeader('Qty'),
              ],
            ),
            ...job.parts.asMap().entries.map((entry) {
              final isEven = entry.key.isEven;
              final part = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : _light,
                ),
                children: [
                  _tableCell(part.name),
                  _tableCell(part.partNumber ?? '-'),
                  _tableCell(part.brand ?? '-'),
                  _tableCell(part.quantity.toString()),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummary(JobModel job) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _primary,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Total Parts:',
              style: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              job.totalPartsCount.toString(),
              style: const pw.TextStyle(
                color: _accent,
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _light,
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _textDark)),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: const pw.TextStyle(color: _textMid)),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureArea() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            height: 60,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Spacer(),
                pw.Text('Mechanic Signature', style: const pw.TextStyle(fontSize: 10, color: _textMid)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            height: 60,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Spacer(),
                pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 10, color: _textMid)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Text(
      'Generated by maochanicProFresh - ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
      style: const pw.TextStyle(fontSize: 9, color: _textMid),
      textAlign: pw.TextAlign.center,
    );
  }

  pw.Widget _infoCell(String label, String value, {PdfColor? valueColor}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _textMid)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? _textDark,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  PdfColor _statusColour(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return const PdfColor.fromInt(0xFF1B4F72);
      case JobStatus.inProgress:
        return const PdfColor.fromInt(0xFFF39C12);
      case JobStatus.completed:
        return const PdfColor.fromInt(0xFF1E8449);
      case JobStatus.cancelled:
        return const PdfColor.fromInt(0xFFC0392B);
    }
  }
}
