# Wize - SOS Emergency Alert App 🚨

Wize is a Flutter-based emergency alert application that allows users to trigger an SOS alert with their current location, send an SMS to emergency contacts, and log the alert to Firebase Firestore. Designed with safety in mind, it's perfect for quick, reliable assistance in emergencies.

## 🚀 Features

- 🔘 **Trigger SOS Alert** with a single tap  
- 📍 **Live Location** sent via SMS (Google Maps link)  
- 🆘 **Custom Emergency Contacts** form  
- 🔔 **Local Notifications** when SOS is sent  
- ☁️ **Firebase Firestore Integration** to store alert data  

## 🛠️ Getting Started

To get this project up and running locally:

1. **Clone the repository**
   ```bash
   git clone https://github.com/Anantaag/wize.git
   cd wize
2. **Install dependencies**






## Requirements

- Flutter SDK >=3.6.1 <4.0.0
- Android Studio / VS Code with Flutter & Dart plugins
- Firebase project setup (Firebase Auth, Firestore, Storage)

## Dependencies

This project uses the following main dependencies:

- *firebase_core* ^2.32.0  
- *firebase_auth* ^4.20.0  
- *cloud_firestore* ^4.17.3  
- *firebase_storage* ^11.7.5  
- *geolocator* ^10.1.1  
- *flutter_sms* (custom local fix version)  
- *flutter_local_notifications* ^17.2.4  
- *flutter_map* ^8.1.1  
- *latlong2* ^0.9.1  
- *image_picker* ^1.1.1  
- *permission_handler* ^11.3.1  
- *provider* ^6.1.2  
- *url_launcher* ^6.3.2  
- *mailer* ^6.5.0 (for email alerts)  
- *quick_actions* ^1.0.2 (for home screen shortcuts)  





Set up Firebase

3. **Add your google-services.json file to android/app/**

4. **Run the app**

bash

flutter pub get

flutter run


⚠️ This app requires location and SMS permissions. Use a real device for testing.

📚 Resources
Flutter Docs

Firebase Docs

FlutterFire CLI Setup

👩‍💻 Developed by Ananta Agarwal


