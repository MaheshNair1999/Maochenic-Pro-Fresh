/// Base class for app-specific errors.
abstract class AppError implements Exception {
  final String message;
  const AppError(this.message);

  @override
  String toString() => message;
}

/// Thrown when a database operation fails.
class DatabaseError extends AppError {
  const DatabaseError(super.message);
}

/// Thrown when OCR fails to process an image.
class OcrError extends AppError {
  const OcrError(super.message);
}

/// Thrown when AI recognition fails.
class AiRecognitionError extends AppError {
  const AiRecognitionError(super.message);
}

/// Thrown when camera operations fail.
class CameraError extends AppError {
  const CameraError(super.message);
}

/// Thrown when PDF generation fails.
class PdfGenerationError extends AppError {
  const PdfGenerationError(super.message);
}

/// Thrown when a required item is not found.
class NotFoundError extends AppError {
  const NotFoundError(super.message);
}
