# PushPilot Backend API

Secure Node.js & Express server handling Firebase Admin SDK initialization, credential verification, and Firebase Cloud Messaging (FCM) HTTP v1 dispatch for the PushPilot Flutter Web application.

---

## 🔒 Security Principles

1. **Zero-Retention In-Memory Credentials**: Uploaded Firebase Service Account private keys are never persisted to disk or written to a database. They are initialized in-memory with automatic TTL expiration.
2. **Private Key Masking**: Service account private keys, client secret tokens, and full device tokens are strictly shielded from logs and browser responses.
3. **CORS & Rate Limiting**: All API endpoints are protected with `express-rate-limit` and configured CORS policies.
4. **FCM HTTP v1 Standard**: Full migration from legacy FCM API to Google's standard OAuth 2.0 / HTTP v1 protocol.

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Default configuration:
```env
PORT=5050
NODE_ENV=development
CORS_ORIGIN=*
RATE_LIMIT_MAX=300
SESSION_TIMEOUT_MINUTES=60
```

### 3. Run the Server
```bash
# Production start
npm start

# Development with hot-reload
npm run dev
```

The server will start listening at:
`http://localhost:5050`

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Healthcheck and backend version |
| `POST` | `/api/project/connect` | Validates service account JSON & establishes an active session |
| `POST` | `/api/project/disconnect` | Deletes the Firebase Admin app instance and cleans up memory |
| `POST` | `/api/notifications/send` | Sends FCM notification to one or multiple device tokens |
| `POST` | `/api/notifications/test` | Dispatches a quick test notification |
| `GET` | `/api/notifications/history` | Retrieves recent notification audit logs |
| `GET` | `/api/stats` | Returns total requests, successes, and failure metrics |

---

## 🧪 Running Unit Tests

```bash
npm test
```
Verifies service account JSON validation, token masking, error translation, and detection of accidental Android `google-services.json` uploads.
