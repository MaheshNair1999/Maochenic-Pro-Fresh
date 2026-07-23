import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';

/// Utility functions for image handling.
class ImageUtils {
  ImageUtils._();

  /// Compresses and resizes an image file.
  /// Returns the path to the processed file.
  static Future<String> compressImage(String inputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return inputPath;

    // Resize if larger than max dimension
    img.Image processed = original;
    if (original.width > AppConstants.maxImageDimension ||
        original.height > AppConstants.maxImageDimension) {
      processed = img.copyResize(
        original,
        width: original.width > original.height
            ? AppConstants.maxImageDimension
            : null,
        height: original.height >= original.width
            ? AppConstants.maxImageDimension
            : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // Save compressed JPEG
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'compressed'));
    await outDir.create(recursive: true);

    final filename = p.basenameWithoutExtension(inputPath);
    final outPath = p.join(outDir.path, '${filename}_c.jpg');

    final jpeg = img.encodeJpg(
      processed,
      quality: AppConstants.imageQuality.toInt(),
    );
    await File(outPath).writeAsBytes(jpeg);
    return outPath;
  }

  /// Normalizes camera output before sending it to OCR or Gemini.
  static Future<String> prepareForAi(String inputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return inputPath;

    var processed = img.bakeOrientation(original);
    if (processed.width > 1600 || processed.height > 1600) {
      processed = img.copyResize(
        processed,
        width: processed.width > processed.height ? 1600 : null,
        height: processed.height >= processed.width ? 1600 : null,
        interpolation: img.Interpolation.cubic,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'ai_ready'));
    await outDir.create(recursive: true);

    final filename = p.basenameWithoutExtension(inputPath);
    final outPath = p.join(outDir.path, '${filename}_ai.jpg');
    await File(outPath).writeAsBytes(img.encodeJpg(processed, quality: 92));
    return outPath;
  }

  /// Deletes an image file if it exists.
  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Generates a unique filename for a photo.
  static String generatePhotoName() {
    return 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}

/// Formats a DateTime to a human-readable "X time ago" string.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 365) {
    return '${(diff.inDays / 365).floor()}y ago';
  } else if (diff.inDays > 30) {
    return '${(diff.inDays / 30).floor()}mo ago';
  } else if (diff.inDays > 0) {
    return '${diff.inDays}d ago';
  } else if (diff.inHours > 0) {
    return '${diff.inHours}h ago';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}
