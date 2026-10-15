const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// In-memory active project sessions
// Map<sessionId, { app: admin.app.App, projectId: string, clientEmail: string, connectedAt: Date, lastActive: Date }>
const activeSessions = new Map();

// In-memory notification history (sanitized, masked)
// Array of history objects
const notificationHistory = [];
const MAX_HISTORY_RECORDS = 200;

// Auto-cleanup stale sessions every 15 minutes
const SESSION_TTL_MS = (parseInt(process.env.SESSION_TIMEOUT_MINUTES, 10) || 60) * 60 * 1000;
setInterval(() => {
  const now = Date.now();
  for (const [sessionId, session] of activeSessions.entries()) {
    if (now - session.lastActive.getTime() > SESSION_TTL_MS) {
      try {
        session.app.delete();
      } catch (err) {
        // App might already be deleted
      }
      activeSessions.delete(sessionId);
    }
  }
}, 15 * 60 * 1000);

/**
 * Mask an FCM token for privacy in logs and responses
 * e.g. "eN1a2b...9z8y7x"
 */
function maskToken(token) {
  if (!token || typeof token !== 'string') return 'invalid-token';
  const trimmed = token.trim();
  if (trimmed.length <= 12) return '******';
  return `${trimmed.slice(0, 6)}...${trimmed.slice(-6)}`;
}

/**
 * Validate service account JSON format and provide clear, human-friendly error messages
 */
function validateServiceAccountJson(jsonContent) {
  let parsed;
  if (typeof jsonContent === 'string') {
    try {
      parsed = JSON.parse(jsonContent);
    } catch (e) {
      throw new Error('Invalid JSON format: The uploaded file could not be parsed as JSON. Please ensure it is a valid Firebase Service Account JSON file.');
    }
  } else if (typeof jsonContent === 'object' && jsonContent !== null) {
    parsed = jsonContent;
  } else {
    throw new Error('Invalid credentials format provided.');
  }

  // Check for common mistake: Android google-services.json
  if (parsed.project_info || parsed.client || parsed.configuration_version) {
    throw new Error(
      "You have uploaded an Android client 'google-services.json' file instead of a Firebase Service Account JSON!\n\n" +
      "To download the correct Service Account JSON:\n" +
      "1. Open Firebase Console (https://console.firebase.google.com)\n" +
      "2. Go to Project Settings (Gear icon) -> 'Service Accounts' tab\n" +
      "3. Click 'Generate new private key'\n" +
      "4. Upload the generated .json file here."
    );
  }

  // Check for iOS GoogleService-Info.plist in JSON form
  if (parsed.CLIENT_ID || parsed.REVERSED_CLIENT_ID || parsed.API_KEY) {
    throw new Error(
      "You have uploaded client-side iOS credentials instead of a Firebase Service Account JSON! Please generate a private key under Firebase Console -> Project Settings -> Service Accounts."
    );
  }

  // Required fields for Firebase Admin SDK
  const requiredFields = ['project_id', 'private_key', 'client_email'];
  const missing = requiredFields.filter((field) => !parsed[field]);
  if (missing.length > 0) {
    throw new Error(`Missing required service account field(s): ${missing.join(', ')}. Please ensure this is an official Google Cloud / Firebase service account private key file.`);
  }

  if (parsed.type && parsed.type !== 'service_account') {
    throw new Error(`Invalid credential type '${parsed.type}'. Expected 'service_account'.`);
  }

  // Verify private key format
  if (typeof parsed.private_key !== 'string' || !parsed.private_key.includes('BEGIN PRIVATE KEY')) {
    throw new Error("Invalid 'private_key' format. The key must begin with '-----BEGIN PRIVATE KEY-----'.");
  }

  return parsed;
}

/**
 * Connect and initialize a Firebase project using in-memory service account
 */
async function connectProject(serviceAccountData) {
  const credentials = validateServiceAccountJson(serviceAccountData);
  const projectId = credentials.project_id;
  const clientEmail = credentials.client_email;

  // Generate unique session ID for isolation
  const sessionId = uuidv4();
  const appName = `pushpilot-${projectId}-${sessionId.slice(0, 8)}`;

  let app;
  try {
    app = admin.initializeApp(
      {
        credential: admin.credential.cert(credentials),
        projectId: projectId,
      },
      appName
    );
  } catch (error) {
    throw new Error(`Failed to initialize Firebase Admin SDK: ${error.message}`);
  }

  const session = {
    sessionId,
    appName,
    app,
    projectId,
    clientEmail,
    connectedAt: new Date(),
    lastActive: new Date(),
  };

  activeSessions.set(sessionId, session);

  return {
    sessionId,
    projectId,
    clientEmail,
    connectedAt: session.connectedAt.toISOString(),
  };
}

/**
 * Disconnect an active session and cleanup Firebase app
 */
async function disconnectProject(sessionId) {
  if (!sessionId) return false;
  const session = activeSessions.get(sessionId);
  if (session) {
    try {
      await session.app.delete();
    } catch (e) {
      // Ignored
    }
    activeSessions.delete(sessionId);
    return true;
  }
  return false;
}

/**
 * Get active session or throw
 */
function getSession(sessionId) {
  const session = activeSessions.get(sessionId);
  if (!session) {
    throw new Error('Session expired or not found. Please connect your Firebase service account again.');
  }
  session.lastActive = new Date();
  return session;
}

/**
 * Translate raw FCM error codes to human-friendly actionable feedback
 */
function translateFcmError(error) {
  const code = error.code || 'messaging/unknown-error';
  const rawMessage = error.message || 'Unknown error occurred';

  switch (code) {
    case 'messaging/invalid-registration-token':
      return {
        code,
        message: 'Invalid FCM registration token format. Check for whitespace or truncation.',
        action: 'Verify that the token copied from your client app is complete and unmodified.',
      };
    case 'messaging/registration-token-not-registered':
      return {
        code,
        message: 'The device token is no longer registered or has been revoked/uninstalled.',
        action: 'Relaunch the client app to request a fresh FCM device token.',
      };
    case 'messaging/mismatched-credential':
      return {
        code,
        message: 'Mismatched credentials! The device token belongs to a different Firebase Project than the uploaded Service Account.',
        action: 'Ensure the client app is configured with the same Firebase Project ID as this service account.',
      };
    case 'messaging/message-rate-exceeded':
      return {
        code,
        message: 'FCM message rate limit exceeded for this device or project.',
        action: 'Slow down sending frequency or wait a few moments before retrying.',
      };
    case 'messaging/authentication-error':
      return {
        code,
        message: 'Authentication failed with Firebase Cloud Messaging servers.',
        action: 'Check that your Service Account has the "Firebase Cloud Messaging API (V1)" enabled in Google Cloud Console and the "Firebase Admin SDK Administrator Service Agent" or "Firebase Cloud Messaging Admin" role.',
      };
    case 'messaging/server-unavailable':
      return {
        code,
        message: 'Firebase FCM server is temporarily unavailable.',
        action: 'Retry the request with exponential backoff.',
      };
    case 'messaging/invalid-argument':
      return {
        code,
        message: `Invalid argument in notification payload: ${rawMessage}`,
        action: 'Review your title, body, image URL, or custom data key-values.',
      };
    default:
      return {
        code,
        message: rawMessage,
        action: 'Check Firebase Cloud Messaging status and verify your project permissions.',
      };
  }
}

/**
 * Sanitize custom key-value data to string values (required by FCM HTTP v1)
 */
function sanitizeDataPayload(data) {
  if (!data || typeof data !== 'object') return {};
  const sanitized = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) continue;
    if (typeof value === 'object') {
      sanitized[String(key)] = JSON.stringify(value);
    } else {
      sanitized[String(key)] = String(value);
    }
  }
  return sanitized;
}

/**
 * Send notification to one or multiple device tokens
 */
async function sendNotification({
  sessionId,
  serviceAccount, // optional direct upload if session was not established
  tokens,
  title,
  body,
  imageUrl,
  data = {},
  priority = 'high',
}) {
  let session;
  let tempApp = null;

  try {
    if (sessionId && activeSessions.has(sessionId)) {
      session = getSession(sessionId);
    } else if (serviceAccount) {
      // Temporary connection
      const credentials = validateServiceAccountJson(serviceAccount);
      const tempAppName = `pushpilot-temp-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      tempApp = admin.initializeApp(
        {
          credential: admin.credential.cert(credentials),
          projectId: credentials.project_id,
        },
        tempAppName
      );
      session = {
        app: tempApp,
        projectId: credentials.project_id,
        clientEmail: credentials.client_email,
      };
    } else {
      throw new Error('No active Firebase project connection. Please connect your service account first.');
    }

    // Validate tokens array
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new Error('At least one valid device FCM token is required.');
    }

    const cleanTokens = tokens
      .map((t) => (typeof t === 'string' ? t.trim() : ''))
      .filter((t) => t.length > 0);

    if (cleanTokens.length === 0) {
      throw new Error('No non-empty device FCM tokens provided.');
    }

    if (!title || !title.trim()) {
      throw new Error('Notification title cannot be empty.');
    }
    if (!body || !body.trim()) {
      throw new Error('Notification message body cannot be empty.');
    }

    const cleanTitle = title.trim();
    const cleanBody = body.trim();
    const cleanImageUrl = imageUrl && imageUrl.trim() ? imageUrl.trim() : null;
    const sanitizedData = sanitizeDataPayload(data);

    const messaging = session.app.messaging();

    // Build base message configuration
    const notificationContent = {
      title: cleanTitle,
      body: cleanBody,
      ...(cleanImageUrl ? { imageUrl: cleanImageUrl } : {}),
    };

    const androidConfig = {
      priority: priority === 'normal' ? 'normal' : 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        ...(cleanImageUrl ? { imageUrl: cleanImageUrl } : {}),
      },
    };

    const apnsConfig = {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true,
          alert: {
            title: cleanTitle,
            body: cleanBody,
          },
        },
      },
      ...(cleanImageUrl
        ? {
            fcmOptions: {
              imageUrl: cleanImageUrl,
            },
          }
        : {}),
    };

    const webpushConfig = {
      notification: {
        title: cleanTitle,
        body: cleanBody,
        icon: '/favicon.png',
        ...(cleanImageUrl ? { image: cleanImageUrl } : {}),
      },
    };

    const results = [];
    let successCount = 0;
    let failureCount = 0;

    // Send single message
    if (cleanTokens.length === 1) {
      const singleToken = cleanTokens[0];
      const message = {
        token: singleToken,
        notification: notificationContent,
        data: sanitizedData,
        android: androidConfig,
        apns: apnsConfig,
        webpush: webpushConfig,
      };

      try {
        const responseId = await messaging.send(message);
        successCount++;
        results.push({
          token: maskToken(singleToken),
          success: true,
          messageId: responseId,
        });
      } catch (err) {
        failureCount++;
        const parsedErr = translateFcmError(err);
        results.push({
          token: maskToken(singleToken),
          success: false,
          error: parsedErr,
        });
      }
    } else {
      // Multicast message (sendEachForMulticast)
      const multicastMessage = {
        tokens: cleanTokens,
        notification: notificationContent,
        data: sanitizedData,
        android: androidConfig,
        apns: apnsConfig,
        webpush: webpushConfig,
      };

      const batchResponse = await messaging.sendEachForMulticast(multicastMessage);
      successCount = batchResponse.successCount;
      failureCount = batchResponse.failureCount;

      batchResponse.responses.forEach((resp, idx) => {
        const token = cleanTokens[idx];
        if (resp.success) {
          results.push({
            token: maskToken(token),
            success: true,
            messageId: resp.messageId,
          });
        } else {
          const parsedErr = translateFcmError(resp.error);
          results.push({
            token: maskToken(token),
            success: false,
            error: parsedErr,
          });
        }
      });
    }

    const timestamp = new Date().toISOString();
    const historyItem = {
      id: uuidv4(),
      timestamp,
      projectId: session.projectId,
      title: cleanTitle,
      body: cleanBody,
      imageUrl: cleanImageUrl,
      tokensCount: cleanTokens.length,
      sampleToken: maskToken(cleanTokens[0]),
      successCount,
      failureCount,
      status: failureCount === 0 ? 'SUCCESS' : successCount === 0 ? 'FAILED' : 'PARTIAL',
      results,
      data: sanitizedData,
    };

    // Store in history
    notificationHistory.unshift(historyItem);
    if (notificationHistory.length > MAX_HISTORY_RECORDS) {
      notificationHistory.pop();
    }

    return {
      success: failureCount === 0,
      totalTokens: cleanTokens.length,
      successCount,
      failureCount,
      projectId: session.projectId,
      results,
      historyItem,
      note: 'FCM Acceptance: An acceptance response from FCM HTTP v1 indicates the message has been accepted by Google FCM servers for routing. Delivery to physical devices depends on device connectivity, battery saver, and OS background policies.',
    };
  } finally {
    if (tempApp) {
      try {
        await tempApp.delete();
      } catch (e) {
        // Ignored
      }
    }
  }
}

/**
 * Get notification history filtered by optional projectId
 */
function getHistory(projectId = null) {
  if (projectId) {
    return notificationHistory.filter((item) => item.projectId === projectId);
  }
  return notificationHistory;
}

/**
 * Get overall dashboard statistics
 */
function getStats(projectId = null) {
  const records = getHistory(projectId);
  let totalRequests = records.length;
  let totalTokensSent = 0;
  let successfulDeliveries = 0;
  let failedDeliveries = 0;

  for (const item of records) {
    totalTokensSent += item.tokensCount || 1;
    successfulDeliveries += item.successCount || 0;
    failedDeliveries += item.failureCount || 0;
  }

  return {
    totalRequests,
    totalTokensSent,
    successfulDeliveries,
    failedDeliveries,
    successRate:
      totalTokensSent > 0 ? ((successfulDeliveries / totalTokensSent) * 100).toFixed(1) : '100.0',
    activeSessionsCount: activeSessions.size,
  };
}

module.exports = {
  validateServiceAccountJson,
  connectProject,
  disconnectProject,
  sendNotification,
  getHistory,
  getStats,
  maskToken,
};
