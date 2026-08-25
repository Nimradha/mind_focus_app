# Newra — Mental & Physical Discipline App

A cross-platform mobile application for building mental and physical discipline through a structured **30-day daily habit challenge system**. Newra combines physical activity tracking, guided mindfulness, cognitive training, and smart automation into a single, gamified platform.

---

## Features

### 🧠 Cognitive Challenges
- Word memory game with increasing difficulty across program days
- Timed PDF article reader — "Mark as Done" button is locked until the full reading timer expires, enforcing genuine engagement
- Progressive mental challenges that increase in difficulty as the user advances through the 30-day plan

### 🏃 Physical Activity Timers
- Dedicated running session timer with dynamic audio feedback and in-session mental math challenges
- Guided meditation timer with breathing instructions that evolve based on progress
- Evening imagination/creativity exercise timer

### 🔔 Smart Notification Engine
- Daily notifications fire **without the app ever being opened**, powered by Android `AlarmManager` via `flutter_local_notifications`
- **10:00 AM** — Morning task reminder
- **4:00 PM** — Urgency reminder for incomplete tasks
- **6:00 PM** — Personalized summary: congratulates full completion or lists only the specific tasks the user failed to complete
- Evening popup on the home screen previewing **tomorrow's challenges** based on the user's current program day

### ⏰ Lock Screen Alarm System
- Full-screen alarm interface that appears **directly on the device lock screen** without requiring PIN/unlock
- Implemented using Android `KeyguardManager.requestDismissKeyguard()`, `setShowWhenLocked()`, and `setTurnScreenOn()` via Java `MethodChannel`
- One-tap dismiss with no snooze — enforcing discipline

### 📋 30-Day Structured Plan
- Dynamic daily plan screen that displays challenges specific to the user's current program day
- Rich animated challenge intro screens with word-by-word text reveals and full-screen imagery
- Task completion tracked in real-time via Cloud Firestore

### 💰 Real-Time Savings Tracker
- From Day 7, users log amounts saved by resisting impulse purchases
- Cumulative savings displayed live on the home screen via a Firestore real-time stream listener

### 🏆 Achievement & Gamification
- Built-in achievement system with confetti animations
- Tracks consecutive successful days and rewards consistency

### 🔐 Authentication
- Secure sign-in via **Google** and **Facebook** using Firebase Auth
- Persistent session management — users stay logged in across app restarts

### 🌗 Adaptive UI
- Full **Light and Dark mode** support
- Micro-animations, gradient cards, and word-by-word animated headings

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| Backend | Firebase (Auth, Cloud Firestore) |
| Notifications | flutter_local_notifications, Android AlarmManager |
| Native Android | Java MethodChannel (lock screen flags, battery optimization, overlay permissions) |
| PDF Viewer | Syncfusion Flutter PDF Viewer |
| Audio | audioplayers |
| UI Extras | confetti, shared_preferences |

---

## Architecture Highlights

- **Background Notifications** — Scheduled using `DateTimeComponents.time` so they repeat daily via `AlarmManager` without requiring any app launch
- **Native Bridge** — Custom Java `MethodChannel` handles Android system-level permissions (appear on top, battery optimization ignore, keyguard dismiss)
- **Real-time Data** — Firestore `snapshots()` stream keeps the savings banner and task state live without manual refresh
- **Program Day Logic** — All challenge content, notification messages, and UI elements dynamically adapt based on the number of days since the user's account creation date

---

## Setup

> ⚠️ This project requires a Firebase project to run. The `google-services.json` file is excluded from this repository for security reasons.

1. Clone the repository
2. Add your own `google-services.json` to `android/app/`
3. Enable **Firebase Auth** (Google & Facebook providers) and **Cloud Firestore** in your Firebase console
4. Run `flutter pub get`
5. Run `flutter run`

---

## Screenshots

*Coming soon*

---

## Author

**Nimradha** — [GitHub](https://github.com/Nimradha)
