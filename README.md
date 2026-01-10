# Nanapiyasa - Mobile Learning App for Down Syndrome Students

A comprehensive Flutter-based mobile learning application designed specifically for Down Syndrome students, featuring interactive educational modules, vocational training, and skill development activities with real-time progress tracking.

## Project Overview

Nanapiyasa is an innovative educational platform that leverages mobile technology to provide engaging, accessible learning experiences for students with Down Syndrome. The app combines gamification, text-to-speech guidance, and visual learning techniques to create an inclusive educational environment.

This project develops an AI-powered inclusive education platform for students with Down syndrome in Sri Lanka. It combines a gamified mobile assessment app with IoT heart rate monitoring and ML analysis to determine functional levels and provide personalized recommendations. A real-time teacher dashboard offers visual progress tracking and early alerts for attention or fatigue issues. The vocational training module uses questionnaire-based ML insights to suggest suitable roles (Chef Assistant, Retail Assistant, Cleaning Assistant), while the communication and social skills module delivers multimodal learning with an adaptive ML role-play chatbot to build confidence in greetings, emotions, and conversations all designed to support independence through ethical, non-invasive, and human-centered technology.

## Key Features

### Interactive Learning Modules
- **Kitchen Learning Game**: Hands-on cooking simulations with drag-and-drop interactions
- **Vocational Training**: Job role simulations and skill development
- **Life Skills Development**: Practical daily living skills training
- **Social Skills Enhancement**: Interactive social scenario learning
- **Cognitive Skills Game**: Interactive activities to improve memory and attention
- **Emotional Control Activities**: Emotional regulation and awareness exercises

### Technical Features
- **Text-to-Speech Integration**: Spoken instructions and feedback using `flutter_tts`
- **Visual Celebrations**: Confetti animations for positive reinforcement
- **Machine Learning**: On-device ML inference with TensorFlow Lite
- **IoT Heart Rate Monitoring**: Real-time engagement and emotional state tracking via custom device
- **Responsive Design**: Optimized for tablets and mobile devices
- **Accessibility**: Designed with special needs considerations

## Architecture

<img width="10870" height="8808" alt="AWS VPC Multi-Tier-2026-01-06-113434" src="https://github.com/user-attachments/assets/32a004d9-1e6c-4d2a-bb7d-f554a1ee434a" />


### Technology Stack
- **Framework**: Flutter 3.7.2+
- **Language**: Dart
- **ML Framework**: TensorFlow Lite (tflite_flutter)
- **Audio**: flutter_tts for text-to-speech
- **Animations**: confetti package for celebrations
- **Networking**: cached_network_image for efficient image loading

### Project Structure
```
my_app/
├── lib/
│   ├── main.dart                 # App entry point and navigation
│   ├── auth_service.dart         # Authentication services
│   ├── game_menu.dart           # Main game interface
│   ├── questionnaire_screen.dart # Interactive assessments
│   ├── model_service.dart       # ML model integration
│   └── Vocational/              # Vocational training modules
├── assets/
│   ├── models/                  # TensorFlow Lite models
│   └── images/                  # Educational assets
└── pubspec.yaml                 # Dependencies and configuration
```

## Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK compatible with Flutter version
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development - macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nanapiyasa/Research.git
   cd Research/my_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Ensure Android SDK is installed
- Create an Android virtual device or connect a physical device
- Run: `flutter run -d android`

#### iOS (macOS only)
- Install Xcode from the App Store
- Run: `flutter run -d ios`

#### Web
- Run: `flutter run -d web`

## Machine Learning Integration

The app utilizes TensorFlow Lite for on-device machine learning:
- **Model Storage**: `assets/models/` directory
- **Inference**: Real-time processing without internet dependency
- **Privacy**: All ML processing happens locally on the device

## Dependencies

### Core Dependencies
```yaml
flutter:
  sdk: flutter
flutter_tts: ^4.0.0          # Text-to-speech functionality
confetti: ^0.7.0             # Celebration animations
cached_network_image: ^3.3.0 # Efficient image loading
tflite_flutter: ^0.9.0     # TensorFlow Lite integration
```

### Development Dependencies
```yaml
flutter_test:
  sdk: flutter
flutter_lints: ^5.0.0        # Code quality and style guidelines
```

## Design Principles

### Accessibility
- High contrast color schemes
- Large, readable fonts
- Simple, intuitive navigation
- Audio feedback for all interactions
- Visual cues and animations

### User Experience
- Gamification elements to increase engagement
- Positive reinforcement through celebrations
- Progressive difficulty levels
- Consistent interface patterns
- IoT Heart Rate Monitoring: Tracks real time engagement and emotional state

## Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Test Coverage
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

## Performance Optimization

- **Image Optimization**: Efficient loading and caching
- **Memory Management**: Proper disposal of resources
- **Animation Performance**: Smooth 60fps animations
- **Startup Time**: Optimized app initialization

## Security Considerations

- No personal data collection
- Local storage only
- No network dependencies for core functionality
- Secure ML model handling

## Contributing

We welcome contributions to improve the Nanapiyasa app! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart coding standards
- Write tests for new features
- Ensure accessibility compliance
- Document code changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Contact

For questions, suggestions, or support:
- Project Repository: [https://github.com/Nanapiyasa/Research](https://github.com/Nanapiyasa/Research)
- Issues: [GitHub Issues](https://github.com/Nanapiyasa/Research/issues)

### Version History
- **v1.0.0** - Initial release with core learning modules
- Future versions to include enhanced features and expanded content

---


