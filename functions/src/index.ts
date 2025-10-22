import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';

admin.initializeApp();

/**
 * Verify that the user is authenticated
 */
const authenticateUser = (context: functions.https.CallableContext): string => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use this function'
    );
  }
  return context.auth.uid;
};

/**
 * Check user's daily quota
 * Free tier: 50 messages per day
 */
const checkQuota = async (userId: string): Promise<void> => {
  const today = new Date().toISOString().split('T')[0];
  const usageDocRef = admin.firestore()
    .collection('usage_daily')
    .doc(`${userId}_${today}`);

  const usageDoc = await usageDocRef.get();
  const count = usageDoc.data()?.count || 0;

  // Free tier limit: 50 messages/day
  if (count >= 50) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Daily quota exceeded. You have reached the limit of 50 messages per day.'
    );
  }

  // Increment counter
  await usageDocRef.set(
    {
      count: count + 1,
      userId,
      date: today,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );
};

/**
 * Log message usage to Firestore
 */
const logUsage = async (
  userId: string,
  provider: string,
  messageLength: number,
  responseLength: number
): Promise<void> => {
  await admin.firestore().collection('usage_logs').add({
    userId,
    provider,
    messageLength,
    responseLength,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
};

/**
 * Send a message to Gemini and get a response
 */
export const sendMessage = functions.https.onCall(async (data, context) => {
  try {
    // Authenticate user
    const userId = authenticateUser(context);

    // Check quota
    await checkQuota(userId);

    // Extract parameters
    const { message, provider = 'gemini', conversationId, history } = data;

    if (!message || typeof message !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Message must be a non-empty string'
      );
    }

    // Get API key from Firebase config
    // Set with: firebase functions:config:set gemini.key="YOUR_KEY"
    const apiKey = functions.config().gemini?.key;

    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Gemini API key not configured. Please contact support.'
      );
    }

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    // Build chat history if provided
    let chat;
    if (history && Array.isArray(history) && history.length > 0) {
      const chatHistory = history.map((msg: any) => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }],
      }));
      chat = model.startChat({ history: chatHistory });
    } else {
      chat = model.startChat();
    }

    // Send message and get response
    const result = await chat.sendMessage(message);
    const response = result.response;
    const responseText = response.text();

    // Log usage
    await logUsage(userId, provider, message.length, responseText.length);

    // Return response
    return {
      content: responseText,
      provider: 'gemini',
      timestamp: Date.now(),
      conversationId: conversationId || null,
    };
  } catch (error: any) {
    functions.logger.error('Error in sendMessage:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to process message: ${error.message || 'Unknown error'}`
    );
  }
});

/**
 * Stream a message response from Gemini
 * This is an HTTP function that supports Server-Sent Events (SSE)
 */
export const streamMessage = functions.https.onRequest(async (req, res) => {
  try {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // Verify auth token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).send('Unauthorized: Missing or invalid Authorization header');
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    let userId: string;

    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      userId = decodedToken.uid;
    } catch (error) {
      res.status(401).send('Unauthorized: Invalid token');
      return;
    }

    // Check quota
    await checkQuota(userId);

    // Extract parameters from request body
    const { message, provider = 'gemini', history } = req.body;

    if (!message || typeof message !== 'string') {
      res.status(400).send('Bad Request: Message must be a non-empty string');
      return;
    }

    // Get API key
    const apiKey = functions.config().gemini?.key;

    if (!apiKey) {
      res.status(500).send('Server Error: API key not configured');
      return;
    }

    // Setup Server-Sent Events
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    // Build chat history if provided
    let chat;
    if (history && Array.isArray(history) && history.length > 0) {
      const chatHistory = history.map((msg: any) => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }],
      }));
      chat = model.startChat({ history: chatHistory });
    } else {
      chat = model.startChat();
    }

    // Stream the response
    const result = await chat.sendMessageStream(message);

    let fullResponse = '';

    for await (const chunk of result.stream) {
      const text = chunk.text();
      fullResponse += text;

      // Send chunk as SSE
      res.write(`data: ${JSON.stringify({ content: text })}\n\n`);
    }

    // Log usage
    await logUsage(userId, provider, message.length, fullResponse.length);

    // Send final event
    res.write(`data: ${JSON.stringify({ done: true })}\n\n`);
    res.end();

  } catch (error: any) {
    functions.logger.error('Error in streamMessage:', error);
    res.status(500).send(`Error: ${error.message || 'Unknown error'}`);
  }
});

/**
 * Check user's quota status
 */
export const checkUserQuota = functions.https.onCall(async (data, context) => {
  const userId = authenticateUser(context);

  const today = new Date().toISOString().split('T')[0];
  const usageDocRef = admin.firestore()
    .collection('usage_daily')
    .doc(`${userId}_${today}`);

  const usageDoc = await usageDocRef.get();
  const count = usageDoc.data()?.count || 0;

  return {
    used: count,
    limit: 50,
    remaining: Math.max(0, 50 - count),
    date: today,
  };
});
