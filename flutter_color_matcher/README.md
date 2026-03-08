# Flutter Color Matcher App

This is a Flutter port of the Color Matcher Pro web application.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- An Android or iOS device/emulator.
- A Gemini API Key from Google AI Studio.

## Setup

1. **Create a new Flutter project** (if you haven't already initialized one with these files):
   If you are just copying these files into a new project:
   ```bash
   flutter create color_matcher_pro
   ```
   Then replace the `lib` folder and `pubspec.yaml` with the provided files.

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Environment Variables**:
   Create a `.env` file in the root of the project (next to `pubspec.yaml`) and add your API key:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```

   *Note: You may need to add `.env` to your `pubspec.yaml` assets manually if it's not picked up, although it is configured in the provided pubspec.*

4. **Run the App**:
   ```bash
   flutter run
   ```

## Features

- **Login**: (Simulated) authentication flow.
- **Dashboard**: View recent palettes and stats.
- **Scanner**: Use the device camera to "capture" colors (simulated capture logic).
- **Color Detail**: Detailed analysis of colors using Gemini AI (Psychology, Pantone matching, Harmonious palettes).
