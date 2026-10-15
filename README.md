# PushPilot 🚀
### Modern Firebase FCM Push Notification Console (Flutter Web + Node.js Backend)

**PushPilot** is a modern, responsive, and secure SaaS dashboard built with **Flutter Web** and **Node.js (Express)** that empowers developers, QA engineers, and product teams to test, customize, and dispatch **Firebase Cloud Messaging (FCM)** push notifications to Android and iOS devices using their Firebase service account JSON credentials and device tokens.

---

## 🌟 Key Features

1. **Modern SaaS UI/UX Design**
   - Clean dark and light theme with persistence.
   - Responsive layout adapting seamlessly across desktop, tablet, and mobile screens.
   - Collapsible navigation sidebar and top header with real-time status indicators.
   - Live mobile device preview (toggle between realistic iOS APNs and Android notification cards).

2. **Secure Firebase Service Account Handling**
   - Drag-and-drop file upload area and browse-file picker.
   - Strict client-side and server-side JSON validation.
   - Automatic detection and friendly error message if an Android `google-services.json` file is mistakenly uploaded.
   - Zero-retention in-memory credential storage (no database or disk writes).
   - Instant project disconnect and session replacement.

3. **Notification Composer**
   - Single and multiple device FCM token dispatch (one token per line).
   - Real-time token counter and validation.
   - Notification title, body, and optional image URL with image preview.
   - FCM High / Normal priority switcher.
   - Custom key-value data payload editor with two-way sync: Visual field builder or Raw JSON editor.
   - 1-Click "Load Sample Data" for rapid testing.
   - Confirmation dialog before dispatching to multiple devices.

4. **FCM HTTP v1 Standard Compliance**
   - Powered by official Firebase Admin SDK for Node.js (`firebase-admin`).
   - Dispatches via Google's latest FCM HTTP v1 API.
   - Returns individual token delivery acceptance IDs (`projects/.../messages/...`).
   - Clear distinction between FCM server acceptance vs actual physical device delivery.
   - Human-friendly translation of FCM error codes (`invalid-registration-token`, `registration-token-not-registered`, `mismatched-credential`, etc.).

5. **Delivery Audit History & Dashboard Analytics**
   - Live metric cards: Total Requests, FCM Accepted, Failed Requests, Firebase Project ID.
   - Filter history by status: All, Success, Partial, Failed.
   - Search by notification title, body, device token, or project ID.
   - Per-token error breakdown with actionable resolution tips.
   - Copy token and copy payload buttons.

---

## 🏗️ Architecture Overview

```mermaid
graph TD
    User["User in Browser"] -->|Flutter Web Frontend (Port 8080)| UI["PushPilot UI"]
    UI -->|1. Drag-and-drop / Browse| Key["Service Account JSON"]
    UI -->|2. Compose Notification & Tokens| Payload["Notification Payload"]
    UI -->|HTTP REST API (JSON)| Backend["Node.js Express Backend (Port 5050)"]
    Backend -->|In-Memory Admin SDK App| FBAdmin["Firebase Admin SDK"]
    FBAdmin -->|FCM HTTP v1 (OAuth 2.0)| FCM["Google FCM Servers"]
    FCM -->|Push Message Routing| Devices["Android & iOS Client Devices"]
    FCM -->|Message ID / Error Code| FBAdmin
    FBAdmin -->|Sanitized Response & Masked Tokens| UI
```

---

## 📁 Project Structure

```
PushPilot/
├── lib/                               # Flutter Web Frontend
│   ├── models/
│   │   ├── notification_history_item.dart
│   │   ├── notification_payload.dart
│   │   ├── project_session.dart
│   │   └── send_result.dart
│   ├── providers/
│   │   ├── notification_provider.dart
│   │   ├── project_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── composer_screen.dart
│   │   ├── credentials_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── history_screen.dart
│   │   ├── main_layout_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── storage_service.dart
│   ├── utils/
│   │   ├── app_theme.dart
│   │   ├── constants.dart
│   │   ├── formatters.dart
│   │   └── validators.dart
│   ├── widgets/
│   │   ├── confirm_send_dialog.dart
│   │   ├── drag_drop_upload.dart
│   │   ├── json_editor_widget.dart
│   │   ├── mobile_notification_preview.dart
│   │   ├── sidebar_nav.dart
│   │   ├── stats_card.dart
│   │   ├── status_badge.dart
│   │   └── top_header.dart
│   └── main.dart
│
├── backend/                           # Secure Node.js & Express API
│   ├── routes/
│   │   └── api.js                     # Health, Connect, Disconnect, Send, History, Stats
│   ├── services/
│   │   └── firebaseService.js         # Firebase Admin SDK lifecycle & FCM v1 dispatch
│   ├── test/
│   │   └── backend.test.js            # Unit tests for JSON validation & masking
│   ├── .env.example
│   ├── package.json
│   └── server.js
│
├── test/                              # Flutter unit & widget tests
│   └── widget_test.dart
└── pubspec.yaml
```

---

## 🔑 How to Get Your Firebase Service Account JSON

> **CRITICAL**: Do **NOT** upload Android's `google-services.json` or iOS's `GoogleService-Info.plist`. Those are client configuration files that contain **no private key** and cannot be used by the server to dispatch notifications.

Follow these 5 steps to download the correct file:

1. Open the [Firebase Console](https://console.firebase.google.com).
2. Select your Firebase project.
3. Click the **Project Settings (Gear icon ⚙️)** next to *Project Overview* in the left navigation sidebar.
4. Navigate to the **Service accounts** tab.
5. Under the *Firebase Admin SDK* section, select **Node.js** and click **Generate new private key**.
6. Confirm by clicking **Generate key**. The JSON file will be downloaded to your computer.

### Required IAM Permissions
Ensure your Firebase service account has either:
- **Firebase Admin SDK Administrator Service Agent** (default), or
- **Firebase Cloud Messaging API (V1)** enabled in Google Cloud Console (`fcm.googleapis.com`), with the **Firebase Cloud Messaging Admin** role.

---

## 🛠️ Local Development Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.20.0 or higher)
- [Node.js](https://nodejs.org) (v18.0.0 or higher) and npm

### 1. Start the Backend Server
```bash
cd backend
npm install
cp .env.example .env
npm start
```
The backend will launch at `http://localhost:5050` with healthcheck available at `http://localhost:5050/api/health`.

### 2. Run the Flutter Web Frontend
In another terminal tab at the project root:
```bash
flutter pub get
flutter run -d chrome
```

---

## 🧪 Running Tests

### Backend Unit Tests
```bash
cd backend
npm test
```
Tests service account validation, detection of accidental `google-services.json` upload, token masking, and statistics.

### Flutter Unit & Smoke Tests
```bash
flutter test
```
Tests Flutter validators, token parsing, and desktop dashboard layout rendering.

### Flutter Web Build Verification
```bash
flutter build web
```
Verifies clean compilation into `build/web/`.

---

## 🚀 Production Deployment Guidelines

### 1. Deploying the Node.js Backend
The backend can be deployed to any Node.js hosting platform (Render, Railway, Fly.io, AWS, or DigitalOcean).
Set the following environment variables on your host:
- `PORT=5050` (or host provided port)
- `NODE_ENV=production`
- `CORS_ORIGIN=https://your-flutter-app-domain.web.app`
- `RATE_LIMIT_MAX=300`

### 2. Deploying the Flutter Web Frontend
Build the release bundle:
```bash
flutter build web --release
```
Deploy the generated `build/web/` folder to:
- **Firebase Hosting**: `firebase deploy --only hosting`
- **Vercel / Netlify**: Point root publish directory to `build/web`
- **Nginx / S3 / CloudFront**: Serve `build/web` with index fallback for SPA routing.

---

## 📄 License
MIT License. Built for seamless Firebase push notification management.
#   p u s h p i l o t  
 