# MechPro — Mechanic Workshop Manager

A Flutter mobile app for managing a mechanic workshop. Tracks vehicles, job sheets, and parts inventory, with AI-powered document and part scanning via Google Gemini.

---

## Features

### Vehicles
- Store customer vehicle records (make, model, year, fuel type, VIN, registration plate, colour, mileage, notes)
- Scan a physical registration certificate with the camera — AI reads the document and auto-fills all fields
- Supports standard and Greek/European registration documents

### Job Sheets
- Create and manage job sheets tied to a vehicle
- Set job status: Pending, In Progress, or Completed
- Add description, notes, and parts used per job
- Full job history per vehicle

### Parts Inventory
- Maintain a catalogue of spare parts (name, brand, part number, OEM number, category, quantity, price)
- Scan an unknown part with the camera — AI identifies it and pre-fills the details
- Search and filter inventory

### AI Scanning (Google Gemini Vision)
- **Registration scanner** — photographs a registration certificate and extracts all fields automatically
- **Parts scanner** — photographs a part and identifies name, brand, category, OEM number, and vehicle compatibility
- Gracefully falls back to raw OCR text when the AI rate limit is reached
- Works offline for OCR; requires an internet connection for AI extraction

### Settings
- Enter or update your Gemini API key at runtime — no rebuild needed

---

## Tech Stack

| Layer | Library |
|---|---|
| Framework | Flutter |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` |
| Local database | SQLite via `sqflite` |
| OCR | Google ML Kit Text Recognition |
| AI Vision | Google Generative AI SDK (Gemini) |
| Camera | `image_picker` |
| Persistence | `shared_preferences` |

---

## Setup

### Prerequisites
- Flutter SDK (stable channel)
- Android SDK / Android Studio
- A [Google AI Studio](https://aistudio.google.com/) API key with Gemini access

### Run

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### Build release APK

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key_here
```

The APK is output to `build/app/outputs/flutter-apk/app-release.apk`.

### API key at runtime

You can also skip the `--dart-define` flag and enter your key directly in the app under **Settings → Gemini API Key**. The runtime key takes priority over the build-time one.

---

## Database

SQLite with schema version 2. Tables:

| Table | Description |
|---|---|
| `vehicles` | Customer vehicle records |
| `jobs` | Job sheets linked to vehicles |
| `job_parts` | Parts used per job |
| `inventory` | Workshop parts stock |

---

## AI Rate Limits

The app targets **Gemini Flash** models. Free-tier keys are limited to **2 requests per minute**. When the limit is hit, the scanner shows OCR-extracted text instead and prompts you to wait 30–60 seconds before retrying.

---

## Project Structure

```
lib/
  core/           # Constants, theme, routing
  data/
    datasources/  # SQLite database helper
    models/       # Data models
    repositories/ # Data access layer
  presentation/
    pages/        # UI screens
    providers/    # Riverpod providers
    widgets/      # Shared UI components
  services/
    ai/           # Gemini vision service
    ocr/          # ML Kit OCR service
```

---

## License

MIT
