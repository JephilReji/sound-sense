# SoundSense 📯
SoundSense is an assistive technology solution designed to enhance environmental awareness for individuals with hearing impairments. By leveraging real-time audio analysis and artificial intelligence, the app translates auditory cues into immediate visual and haptic feedback, ensuring users stay safe and connected to their surroundings.

## 🌟 Core Purpose
The primary goal of SoundSense is to bridge the gap between sound and sight. Whether in a busy street or at home, the app acts as a "digital ear," identifying critical sounds that require immediate attention—such as emergency sirens, vehicle horns, or safety alarms—and alerting the user through an intuitive, high-contrast interface.

## 🚀 Key Features

Intelligent Sound Classification: Uses a trained machine learning model to distinguish between various environmental sounds like sirens, horns, and heavy vehicles.


Real-time Decibel Monitoring: A dynamic visual meter that tracks ambient noise levels in real-time, providing a sense of sound intensity.

Background Vigilance: Operates as a persistent foreground service, ensuring the user is protected even when the app is minimized or the screen is locked.

Adaptive Detection Modes:


### Normal Mode: Optimized for outdoor safety and traffic awareness.


### Indoor Mode: Focused on household safety and alarm detection.


High-Urgency Alerts: Tiered alert system that triggers full-screen visual warnings and vibrations based on the danger level of the detected sound.

## 🛠️ Technical Overview

AI Engine: Powered by TensorFlow Lite for efficient, on-device inference without requiring an internet connection.


Audio Processing: High-fidelity PCM16 audio streaming for accurate decibel calculation and classification.


Architecture: Built using Flutter for a smooth, cross-platform experience with a focus on high-performance background isolates.

Permissions & Security: Robust implementation of Android 14+ background microphone and notification standards.

## 📦 Requirements & Setup
### Prerequisites
Flutter SDK (^3.10.8) 

Android Device (API Level 26 or higher) 

TFLite Model and Labels located in assets/models/

Installation
Clone the Repository:

Bash
```
git clone https://github.com/your-repo/sound-sense.git
cd sound_sense_ui
```
Install Dependencies:

Bash
```
flutter pub get
```

Build and Run:

Bash
```
flutter run
```

### 🤝 Contributing
This is a collaborative project. Please ensure all feature additions are tested on the test branch before being merged into dev. Document any changes to the AI model or audio processing logic in the pull request.
