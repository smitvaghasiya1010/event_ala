

📱  Event Planner App

A modern and feature-rich Event Planner mobile application built using Flutter. This app allows users to create, manage, and track events efficiently with a beautiful UI and smooth user experience.

🚀 Features
📅 Add, Edit, Delete Events
🔍 Search Events (by title, location, category)
🗂 Categorized Events (Meeting, Birthday, Trip, etc.)
⏰ Date & Time Picker
📊 Event Statistics (Today, Upcoming, Total)
👤 Profile Management (Change Display Name)
📆 Calendar View with Event Indicators
💾 Local Storage using SharedPreferences
🎨 Modern UI with Material Design
🛠️ Tech Stack

Framework: Flutter
Language: Dart
Storage: SharedPreferences (Local Storage)
UI: Material 3 Design

📂 Project Structure
lib/
 ├── main.dart          # Main application file
 ├── models/            # Event Model
 ├── screens/           # UI Screens (Home, Profile, Add/Edit)
 ├── widgets/           # Reusable UI Components
 └── storage/           # Local Storage Logic
 
📸 Screens Included
🏠 Home Screen (Event List + Search + Stats)
➕ Add/Edit Event Screen
📄 Event Detail Bottom Sheet
👤 Profile Screen with Calendar
⚙️ How It Works
App loads user name & events from local storage
If no events exist → default sample events are created
User can:
Add new events
Edit existing events
Delete events
Events are saved locally using JSON encoding
💡 Key Concepts Used
Stateful Widgets
Navigation (Navigator.push / pop)
Form Validation
JSON Serialization (toJson / fromJson)
Local Persistence
Custom UI Components
▶️ How to Run
Install Flutter
Clone the repository
Run commands:
flutter pub get
flutter run
📦 Dependencies
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.0.0
👨‍💻 Developer

Name: Smit
Project: ALA-3 Event Planner

📌 Version

v1.0.0

🌟 Future Improvements
🔔 Notifications / Reminders
☁️ Cloud Sync (Firebase)
📊 Analytics Dashboard
🌙 Dark Mode
🔐 Authentication System
