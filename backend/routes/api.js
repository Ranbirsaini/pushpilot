const express = require('express');
const router = express.Router();
const firebaseService = require('../services/firebaseService');

/**
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'PushPilot FCM Backend',
    version: '1.0.0',
  });
});

/**
 * Connect Firebase Project with Service Account JSON
 */
router.post('/project/connect', async (req, res) => {
  try {
    const { serviceAccount } = req.body;
    if (!serviceAccount) {
      return res.status(400).json({
        success: false,
        error: 'Missing serviceAccount field. Please provide your Firebase service account JSON.',
      });
    }

    const sessionInfo = await firebaseService.connectProject(serviceAccount);
    return res.json({
      success: true,
      message: 'Firebase project connected successfully.',
      session: sessionInfo,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to connect Firebase project.',
    });
  }
});

/**
 * Disconnect active project
 */
router.post('/project/disconnect', async (req, res) => {
  try {
    const { sessionId } = req.body;
    if (!sessionId) {
      return res.status(400).json({ success: false, error: 'Missing sessionId' });
    }
    const disconnected = await firebaseService.disconnectProject(sessionId);
    return res.json({
      success: true,
      disconnected,
      message: disconnected
        ? 'Project disconnected successfully.'
        : 'Session was not active or already expired.',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Send FCM Notification
 */
router.post('/notifications/send', async (req, res) => {
  try {
    const {
      sessionId,
      serviceAccount,
      tokens,
      title,
      body,
      imageUrl,
      data,
      priority,
    } = req.body;

    if (!tokens || (Array.isArray(tokens) && tokens.length === 0)) {
      return res.status(400).json({
        success: false,
        error: 'At least one device token is required.',
      });
    }

    if (!title || !title.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Notification title is required.',
      });
    }

    if (!body || !body.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Notification body message is required.',
      });
    }

    const result = await firebaseService.sendNotification({
      sessionId,
      serviceAccount,
      tokens: Array.isArray(tokens) ? tokens : [tokens],
      title,
      body,
      imageUrl,
      data,
      priority,
    });

    return res.json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      error: error.message || 'An error occurred while sending notification.',
    });
  }
});

/**
 * Send a Test Notification with sample payload
 */
router.post('/notifications/test', async (req, res) => {
  try {
    const { sessionId, token } = req.body;
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Device token is required to send a test notification.',
      });
    }

    const testTitle = '🚀 PushPilot Test Notification';
    const testBody = `FCM test message dispatched at ${new Date().toLocaleTimeString()}! Your Firebase integration is working smoothly.`;
    const testData = {
      source: 'pushpilot_test',
      timestamp: Date.now().toString(),
      type: 'test_ping',
    };

    const result = await firebaseService.sendNotification({
      sessionId,
      tokens: [token],
      title: testTitle,
      body: testBody,
      data: testData,
    });

    return res.json(result);
  } catch (error) {
    return res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Get notification history
 */
router.get('/notifications/history', (req, res) => {
  try {
    const projectId = req.query.projectId;
    const history = firebaseService.getHistory(projectId);
    return res.json({
      success: true,
      history,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Get stats
 */
router.get('/stats', (req, res) => {
  try {
    const projectId = req.query.projectId;
    const stats = firebaseService.getStats(projectId);
    return res.json({
      success: true,
      stats,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
