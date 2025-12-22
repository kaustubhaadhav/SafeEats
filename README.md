# Food Safety Scanner

A Flutter application that scans food product barcodes, retrieves ingredient information from Open Food Facts, and checks for potential carcinogens using IARC and California Prop 65 databases.

## Features

- **Barcode Scanning**: Scan food product barcodes using your device's camera
- **Ingredient Analysis**: Retrieve and parse ingredient lists from Open Food Facts API
- **Carcinogen Detection**: Check ingredients against IARC classifications and California Prop 65 list
- **Risk Level Assessment**: Visual risk indicators from Safe to Critical based on scientific classifications
- **Scan History**: Keep track of previously scanned products
- **Offline Support**: Local caching of product data and carcinogen database
- **Searchable Database**: Browse and search the complete carcinogen database

## Architecture

This app follows **Clean Architecture** principles with the **BLoC pattern** for state management:

```
lib/
├── core/                    # Core utilities and shared code
│   ├── errors/             # Exception and failure handling
│   ├── network/            # API client and network utilities
│   ├── theme/              # App theming
│   └── utils/              # Ingredient parsing, carcinogen matching
├── features/               # Feature modules
│   ├── scanner/            # Barcode scanning
│   ├── product/            # Product display and analysis
│   ├── carcinogen/         # Carcinogen database
│   ├── history/            # Scan history
│   ├── home/               # Home screen
│   └── settings/           # App settings
├── app.dart                # MaterialApp configuration
├── injection_container.dart # Dependency injection
└── main.dart               # App entry point
```

Each feature follows a three-layer architecture:
- **Presentation**: BLoC, Pages, Widgets
- **Domain**: Entities, Repositories (abstract), Use Cases
- **Data**: Models, Data Sources, Repository Implementations

## Data Sources

### Open Food Facts API
- Free, open-source food product database
- Provides ingredient lists, nutrition info, and product details
- https://world.openfoodfacts.org

### IARC Classifications
International Agency for Research on Cancer classifications:
- **Group 1**: Carcinogenic to humans
- **Group 2A**: Probably carcinogenic to humans
- **Group 2B**: Possibly carcinogenic to humans
- **Group 3**: Not classifiable

### California Proposition 65
- Safe Drinking Water and Toxic Enforcement Act
- List of 900+ chemicals known to cause cancer or reproductive harm

## Risk Levels

| Level | Color | Description |
|-------|-------|-------------|
| Safe | Green | No known carcinogens detected |
| Low | Lime | IARC Group 3 or minimal concern |
| Medium | Amber | IARC Group 2B - Possibly carcinogenic |
| High | Orange | IARC Group 2A - Probably carcinogenic |
| Critical | Red | IARC Group 1 - Known carcinogen |

## Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android device or emulator with camera

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd food_safety_scanner
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Dependencies

| Package | Purpose |
|---------|---------|
| flutter_bloc | State management |
| get_it | Dependency injection |
| dartz | Functional programming (Either type) |
| dio | HTTP client |
| sqflite | Local SQLite database |
| mobile_scanner | Barcode scanning |
| connectivity_plus | Network connectivity |
| equatable | Value equality |
| path_provider | File system paths |

## Usage

### Scanning a Product

1. Open the app and tap the **Scan** tab
2. Point your camera at a food product barcode
3. Wait for the barcode to be detected
4. View the results showing:
   - Product information
   - Ingredient list
   - Detected carcinogens (if any)
   - Overall risk level

### Manual Barcode Entry

If scanning doesn't work, you can enter the barcode manually:
1. Tap "Enter barcode manually" on the scanner screen
2. Type the barcode number
3. Tap "Search"

### Browsing the Database

1. Tap the **Database** tab
2. Search for specific compounds
3. Filter by risk level or source
4. Tap any entry for detailed information

## Permissions

The app requires the following permissions:

| Permission | Purpose |
|------------|---------|
| CAMERA | Scanning product barcodes |
| INTERNET | Fetching product data from Open Food Facts |

## Privacy

- All scan history is stored locally on your device
- No personal data is collected or transmitted
- Product lookups are made anonymously to Open Food Facts API

## Disclaimer

This application is provided for **informational and educational purposes only**.

- Not a substitute for professional medical advice
- Database accuracy cannot be guaranteed
- Many factors affect cancer risk beyond ingredient presence
- Always consult healthcare professionals for medical concerns

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Open Food Facts](https://world.openfoodfacts.org) for the product database
- [IARC](https://monographs.iarc.who.int) for carcinogen classifications
- [California OEHHA](https://oehha.ca.gov/proposition-65) for Prop 65 data