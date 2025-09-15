#!/bin/bash
# Mobile Development Course Setup Script
# Installs mobile development tools and frameworks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "pop" ]] || [[ "$ID" == "elementary" ]] || [[ "$ID" == "linuxmint" ]]; then
                PLATFORM="ubuntu"
            elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "fedora" ]]; then
                PLATFORM="redhat"
            elif [[ "$ID" == "arch" ]] || [[ "$ID" == "manjaro" ]]; then
                PLATFORM="arch"
            else
                PLATFORM="linux"
            fi
        else
            PLATFORM="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi

    log_success "Detected platform: $PLATFORM"
}

# Install Android development tools
install_android_tools() {
    log_info "Installing Android development tools..."

    case $PLATFORM in
        macos)
            # Android Studio
            brew install --cask android-studio

            # Android SDK
            brew install android-sdk

            # Android platform tools
            brew install android-platform-tools
            ;;
        ubuntu)
            # Install Java (required for Android)
            sudo apt install -y openjdk-11-jdk

            # Android Studio
            sudo snap install android-studio --classic

            # Android SDK tools
            sudo apt install -y android-tools-adb android-tools-fastboot
            ;;
        redhat)
            # Install Java
            sudo yum install -y java-11-openjdk-devel

            # Android tools
            sudo yum install -y android-tools
            ;;
        arch)
            # Install Java
            sudo pacman -S --noconfirm jdk11-openjdk

            # Android tools
            sudo pacman -S --noconfirm android-tools
            ;;
        windows)
            log_info "Install Android Studio manually from https://developer.android.com/studio"
            ;;
    esac

    log_success "Android development tools installed"
}

# Install iOS development tools (macOS only)
install_ios_tools() {
    log_info "Installing iOS development tools..."

    if [[ "$PLATFORM" != "macos" ]]; then
        log_warning "iOS development requires macOS. Skipping iOS tools installation."
        return
    fi

    # Xcode
    if ! xcode-select -p &>/dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
    else
        log_success "Xcode Command Line Tools already installed"
    fi

    # Install Xcode from App Store or use xcode-install
    log_info "Please install Xcode from the Mac App Store if not already installed"

    # CocoaPods for iOS dependency management
    sudo gem install cocoapods

    # Carthage (alternative dependency manager)
    brew install carthage

    log_success "iOS development tools installed"
}

# Install React Native development tools
install_react_native_tools() {
    log_info "Installing React Native development tools..."

    # Install Node.js and npm (should already be available from main setup)
    if ! command -v node &>/dev/null; then
        log_error "Node.js not found. Please run the main setup script first."
        exit 1
    fi

    # Install React Native CLI
    npm install -g @react-native-community/cli

    # Install Expo CLI
    npm install -g @expo/cli

    # Install React Native Debugger (optional)
    case $PLATFORM in
        macos)
            brew install --cask react-native-debugger
            ;;
        ubuntu)
            # React Native Debugger not available via apt
            ;;
    esac

    log_success "React Native development tools installed"
}

# Install Flutter development tools
install_flutter_tools() {
    log_info "Installing Flutter development tools..."

    case $PLATFORM in
        macos)
            # Install Flutter
            git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
            export PATH="$PATH:$HOME/flutter/bin"
            flutter precache

            # Install Android Studio if not already installed
            if ! brew list --cask | grep -q android-studio; then
                brew install --cask android-studio
            fi
            ;;
        ubuntu)
            # Install Flutter
            sudo snap install flutter --classic
            flutter sdk-path

            # Add to PATH
            echo 'export PATH="$PATH:$HOME/.flutter/bin"' >> ~/.bashrc
            ;;
        redhat)
            # Install Flutter manually
            git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
            export PATH="$PATH:$HOME/flutter/bin"
            ;;
        arch)
            # Install Flutter
            sudo pacman -S --noconfirm flutter
            ;;
        windows)
            log_info "Install Flutter manually from https://flutter.dev/docs/get-started/install"
            ;;
    esac

    # Configure Flutter
    if command -v flutter &>/dev/null; then
        flutter config --android-studio-dir=/opt/android-studio
        flutter doctor
    fi

    log_success "Flutter development tools installed"
}

# Install mobile testing tools
install_testing_tools() {
    log_info "Installing mobile testing tools..."

    # Install Appium for mobile automation testing
    npm install -g appium
    npm install -g appium-doctor

    # Install Detox for React Native testing
    npm install -g detox-cli

    # Install Flutter testing tools
    if command -v flutter &>/dev/null; then
        flutter pub global activate junitreport
    fi

    log_success "Mobile testing tools installed"
}

# Install mobile development utilities
install_mobile_utils() {
    log_info "Installing mobile development utilities..."

    case $PLATFORM in
        macos)
            # Install fastlane for mobile CI/CD
            brew install fastlane

            # Install imagemagick for icon generation
            brew install imagemagick

            # Install watchman for React Native file watching
            brew install watchman
            ;;
        ubuntu)
            # Install imagemagick
            sudo apt install -y imagemagick

            # Install watchman
            sudo apt install -y watchman
            ;;
        redhat)
            # Install imagemagick
            sudo yum install -y ImageMagick

            # Watchman not available via yum
            ;;
        arch)
            # Install imagemagick
            sudo pacman -S --noconfirm imagemagick

            # Install watchman
            sudo pacman -S --noconfirm watchman
            ;;
        windows)
            log_info "Mobile utilities not available on Windows"
            ;;
    esac

    log_success "Mobile development utilities installed"
}

# Create mobile development course structure
create_course_structure() {
    log_info "Creating mobile development course directory structure..."

    local course_dir="$HOME/dev/current/mobile-course"
    mkdir -p "$course_dir"/{android,ios,react-native,flutter,tests,docs,scripts}

    # Create React Native sample app
    mkdir -p "$course_dir/react-native/MyFirstApp"
    cat << 'EOF' > "$course_dir/react-native/MyFirstApp/package.json"
{
  "name": "MyFirstApp",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "test": "jest",
    "lint": "eslint ."
  },
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.72.6"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@babel/preset-env": "^7.20.0",
    "@babel/runtime": "^7.20.0",
    "@react-native/eslint-config": "^0.72.2",
    "@react-native/metro-config": "^0.72.11",
    "@tsconfig/react-native/tsconfig.json": "^3.0.0",
    "@types/react": "^18.0.24",
    "@types/react-test-renderer": "^18.0.0",
    "babel-jest": "^29.2.1",
    "eslint": "^8.19.0",
    "jest": "^29.2.1",
    "metro-react-native-babel-preset": "0.76.8",
    "prettier": "^2.4.1",
    "react-test-renderer": "18.2.0",
    "typescript": "^4.8.4"
  },
  "engines": {
    "node": ">=16"
  }
}
EOF

    cat << 'EOF' > "$course_dir/react-native/MyFirstApp/App.tsx"
import React from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';

import {
  Colors,
} from 'react-native/Libraries/NewAppScreen';

function App(): JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <View style={styles.sectionContainer}>
          <Text style={[styles.sectionTitle, {color: isDarkMode ? Colors.white : Colors.black}]}>
            Welcome to Mobile Development!
          </Text>
          <Text style={[styles.sectionDescription, {color: isDarkMode ? Colors.light : Colors.dark}]}>
            This is your first React Native app. Edit App.tsx to see changes.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
});

export default App;
EOF

    # Create Flutter sample app
    mkdir -p "$course_dir/flutter/my_first_app"
    cat << 'EOF' > "$course_dir/flutter/my_first_app/pubspec.yaml"
name: my_first_app
description: A new Flutter project.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
EOF

    cat << 'EOF' > "$course_dir/flutter/my_first_app/lib/main.dart"
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Development Course',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Welcome to Flutter!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
EOF

    # Create Android sample app (Java)
    mkdir -p "$course_dir/android/MyFirstAndroidApp/app/src/main/java/com/example/myfirstandroidapp"
    cat << 'EOF' > "$course_dir/android/MyFirstAndroidApp/app/src/main/java/com/example/myfirstandroidapp/MainActivity.java"
package com.example.myfirstandroidapp;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    private TextView textView;
    private Button button;
    private int counter = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        textView = findViewById(R.id.textView);
        button = findViewById(R.id.button);

        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                counter++;
                textView.setText("Button clicked " + counter + " times!");
            }
        });
    }
}
EOF

    # Create iOS sample app (Swift)
    mkdir -p "$course_dir/ios/MyFirstiOSApp/MyFirstiOSApp"
    cat << 'EOF' > "$course_dir/ios/MyFirstiOSApp/MyFirstiOSApp/ContentView.swift"
import SwiftUI

struct ContentView: View {
    @State private var counter = 0

    var body: some View {
        VStack {
            Text("Welcome to iOS Development!")
                .font(.title)
                .padding()

            Text("Button tapped \(counter) times")
                .font(.headline)

            Button(action: {
                counter += 1
            }) {
                Text("Tap me!")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    preview: some View {
        ContentView()
    }
}
EOF

    # Create build scripts
    cat << 'EOF' > "$course_dir/scripts/setup-react-native.sh"
#!/bin/bash
# Setup script for React Native development

echo "Setting up React Native development environment..."

# Navigate to React Native project
cd ../react-native/MyFirstApp

# Install dependencies
npm install

# For iOS (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd ios && pod install && cd ..
fi

echo "React Native setup complete!"
echo "Run: npm start"
echo "Android: npm run android"
echo "iOS: npm run ios"
EOF
    chmod +x "$course_dir/scripts/setup-react-native.sh"

    cat << 'EOF' > "$course_dir/scripts/setup-flutter.sh"
#!/bin/bash
# Setup script for Flutter development

echo "Setting up Flutter development environment..."

# Navigate to Flutter project
cd ../flutter/my_first_app

# Get dependencies
flutter pub get

# Check Flutter setup
flutter doctor

echo "Flutter setup complete!"
echo "Run: flutter run"
echo "Build APK: flutter build apk"
echo "Build iOS: flutter build ios"
EOF
    chmod +x "$course_dir/scripts/setup-flutter.sh"

    # Create README
    cat << EOF > "$course_dir/README.md"
# Mobile Development Course

## Course Overview

This course covers mobile application development for Android and iOS platforms using modern frameworks and tools.

### Topics Covered
- Native Android Development (Java/Kotlin)
- Native iOS Development (Swift)
- Cross-platform Development (React Native, Flutter)
- Mobile UI/UX Design
- App Store Deployment
- Testing and Debugging

## Development Environments

### Android Development
- **IDE**: Android Studio
- **Language**: Java/Kotlin
- **SDK**: Android SDK
- **Emulator**: Android Emulator

### iOS Development (macOS only)
- **IDE**: Xcode
- **Language**: Swift
- **SDK**: iOS SDK
- **Simulator**: iOS Simulator

### Cross-Platform Development
- **React Native**: JavaScript/TypeScript + React
- **Flutter**: Dart

## Getting Started

### 1. Environment Setup
Run the appropriate setup scripts in the \`scripts/\` directory:

\`\`\`bash
# React Native setup
./scripts/setup-react-native.sh

# Flutter setup
./scripts/setup-flutter.sh
\`\`\`

### 2. Running Sample Apps

#### React Native
\`\`\`bash
cd react-native/MyFirstApp
npm start          # Start Metro bundler
npm run android    # Run on Android
npm run ios        # Run on iOS
\`\`\`

#### Flutter
\`\`\`bash
cd flutter/my_first_app
flutter run        # Run on connected device/emulator
flutter run -d emulator-5554  # Run on specific emulator
\`\`\`

#### Android Studio
1. Open Android Studio
2. Import project: \`android/MyFirstAndroidApp\`
3. Run > Run 'app'

#### Xcode (macOS)
1. Open Xcode
2. Open project: \`ios/MyFirstiOSApp/MyFirstiOSApp.xcodeproj\`
3. Select simulator and run

## Development Tools

### Android Tools
\`\`\`bash
# ADB (Android Debug Bridge)
adb devices                    # List connected devices
adb logcat                     # View device logs
adb shell                      # Access device shell

# Android Emulator
emulator -list-avds            # List available emulators
emulator -avd <avd_name>       # Start emulator
\`\`\`

### iOS Tools (macOS)
\`\`\`bash
# Xcode tools
xcode-select -p               # Check Xcode path
xcrun simctl list devices     # List simulators
xcrun simctl boot <device_id> # Boot simulator
\`\`\`

### React Native Tools
\`\`\`bash
# Metro bundler
npm start

# React Native Debugger
npm install -g react-native-debugger
react-native-debugger

# Expo (if using Expo)
expo start
\`\`\`

### Flutter Tools
\`\`\`bash
# Flutter CLI
flutter doctor                 # Check environment
flutter devices               # List devices
flutter create my_app         # Create new app
flutter pub get              # Get dependencies
flutter run                   # Run app
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
\`\`\`

## Testing

### Android Testing
\`\`\`bash
# Unit tests
./gradlew test

# Instrumentation tests
./gradlew connectedAndroidTest

# UI tests (Espresso)
./gradlew connectedCheck
\`\`\`

### iOS Testing
\`\`\`bash
# Unit tests
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 14'

# UI tests
xcodebuild test -scheme MyAppUITests -destination 'platform=iOS Simulator,name=iPhone 14'
\`\`\`

### React Native Testing
\`\`\`bash
# Jest unit tests
npm test

# Detox E2E tests
detox build -c ios.sim.debug
detox test -c ios.sim.debug
\`\`\`

### Flutter Testing
\`\`\`bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter drive --target=test_driver/app.dart
\`\`\`

## Debugging

### Android Debugging
- Use Android Studio debugger
- Logcat for logging
- ADB for device interaction
- Stetho for network inspection

### iOS Debugging
- Xcode debugger
- Console.app for logging
- Instruments for performance profiling

### React Native Debugging
- Chrome DevTools
- React Native Debugger
- Flipper

### Flutter Debugging
- Flutter DevTools
- Observatory
- Android Studio/VS Code debugger

## Deployment

### Android Deployment
\`\`\`bash
# Build release APK
./gradlew assembleRelease

# Build bundle
./gradlew bundleRelease

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore app-release-unsigned.apk alias_name

# Align APK
zipalign -v 4 app-release-unsigned.apk MyApp.apk
\`\`\`

### iOS Deployment
1. Create Apple Developer account
2. Configure provisioning profiles
3. Archive app in Xcode
4. Upload to App Store Connect

### React Native Deployment
\`\`\`bash
# Android
cd android && ./gradlew assembleRelease

# iOS
cd ios && xcodebuild -scheme MyApp archive
\`\`\`

### Flutter Deployment
\`\`\`bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
\`\`\`

## Best Practices

### Architecture
- **Android**: MVVM, Clean Architecture
- **iOS**: MVC, MVVM, VIPER
- **React Native**: Redux, Context API
- **Flutter**: Provider, Riverpod, BLoC

### Performance
- Optimize images and assets
- Use appropriate data structures
- Implement lazy loading
- Profile with tools (Android Profiler, Instruments, etc.)

### Security
- Secure API keys
- Implement proper authentication
- Use HTTPS
- Validate input data
- Store sensitive data securely

### UI/UX
- Follow platform design guidelines
- Support different screen sizes
- Implement accessibility
- Test on multiple devices

## Resources

### Official Documentation
- [Android Developers](https://developer.android.com/)
- [Apple Developer](https://developer.apple.com/)
- [React Native](https://reactnative.dev/)
- [Flutter](https://flutter.dev/)

### Learning Resources
- [Android Developer Guides](https://developer.android.com/guide)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [React Native Tutorial](https://reactnative.dev/docs/tutorial)
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)

### Tools and Libraries
- [Android Jetpack](https://developer.android.com/jetpack)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [React Native Elements](https://react-native-elements.github.io/react-native-elements/)
- [Flutter Packages](https://pub.dev/)

### Communities
- [Stack Overflow](https://stackoverflow.com/questions/tagged/android+ios+react-native+flutter)
- [Reddit r/androiddev](https://www.reddit.com/r/androiddev/)
- [Reddit r/iOSProgramming](https://www.reddit.com/r/iOSProgramming)
- [React Native Community](https://reactnative.dev/community/overview)
- [Flutter Community](https://flutter.dev/community)

## Course Projects

### Project 1: Calculator App
- Basic arithmetic operations
- Clean UI design
- Input validation

### Project 2: Todo List App
- Add/edit/delete tasks
- Data persistence
- Categories and priorities

### Project 3: Weather App
- API integration
- Location services
- Data visualization

### Project 4: Social Media App
- User authentication
- Real-time updates
- Media upload

## Assessment

### Weekly Assignments
- Code reviews
- Unit tests
- Documentation

### Final Project
- Complete mobile application
- App Store deployment
- Presentation and demo

## Support

### Getting Help
1. Check documentation first
2. Search Stack Overflow
3. Ask in course forums
4. Office hours with instructor

### Common Issues
- **Android**: Clear gradle cache, restart Android Studio
- **iOS**: Clean build folder, restart Xcode
- **React Native**: Clear Metro cache, reinstall node_modules
- **Flutter**: flutter clean, flutter pub cache repair

Happy mobile development! 📱
EOF

    log_success "Mobile development course structure created at $course_dir"
}

# Verify installations
verify_installation() {
    log_info "Verifying mobile development installations..."

    local errors=0

    # Check Node.js and npm
    for tool in node npm; do
        if command -v $tool &>/dev/null; then
            log_success "$tool: available"
        else
            log_error "$tool: NOT FOUND"
            ((errors++))
        fi
    done

    # Check React Native CLI
    if command -v npx &>/dev/null && npx react-native --version &>/dev/null; then
        log_success "React Native CLI: available"
    else
        log_error "React Native CLI: NOT FOUND"
        ((errors++))
    fi

    # Check Flutter
    if command -v flutter &>/dev/null; then
        log_success "Flutter: available"
    else
        log_error "Flutter: NOT FOUND"
        ((errors++))
    fi

    # Check Android tools
    if command -v adb &>/dev/null; then
        log_success "Android Debug Bridge: available"
    else
        log_warning "Android Debug Bridge: NOT FOUND (install Android SDK)"
    fi

    # Check iOS tools (macOS only)
    if [[ "$PLATFORM" == "macos" ]]; then
        if xcode-select -p &>/dev/null; then
            log_success "Xcode Command Line Tools: available"
        else
            log_error "Xcode Command Line Tools: NOT FOUND"
            ((errors++))
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All mobile development tools verified successfully!"
    else
        log_warning "$errors mobile development tools failed verification."
    fi
}

# Main function
main() {
    echo -e "${BLUE}📱 Setting up Mobile Development Course Environment${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    detect_platform

    install_android_tools
    install_ios_tools
    install_react_native_tools
    install_flutter_tools
    install_testing_tools
    install_mobile_utils
    create_course_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 Mobile Development course setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the course materials in ~/dev/current/mobile-course/"
    echo "2. Set up React Native: cd ~/dev/current/mobile-course && ./scripts/setup-react-native.sh"
    echo "3. Set up Flutter: ./scripts/setup-flutter.sh"
    echo "4. Open Android Studio for Android development"
    echo "5. Open Xcode for iOS development (macOS only)"
    echo ""
    echo -e "${BLUE}Happy mobile development! 🚀${NC}"
}

# Run main function
main "$@"
