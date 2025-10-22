# Firebase Cloud Functions - AI Life Assistant Pro

Backend Cloud Functions for AI chat functionality.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure API Keys

Set your Gemini API key using Firebase CLI:

```bash
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY_HERE"
```

Get your free Gemini API key from: https://makersuite.google.com/app/apikey

### 3. Build Functions

```bash
npm run build
```

## Deploy

Deploy all functions to Firebase:

```bash
firebase deploy --only functions
```

Or deploy specific functions:

```bash
firebase deploy --only functions:sendMessage
firebase deploy --only functions:streamMessage
firebase deploy --only functions:checkUserQuota
```

## Available Functions

### `sendMessage` (Callable Function)
Sends a message to an AI provider and returns the response.

**Parameters:**
- `message` (string): The user's message
- `provider` (string): AI provider ('gemini', 'claude', or 'openai')
- `history` (array, optional): Chat history

**Returns:**
- `content` (string): AI response text
- `provider` (string): Provider used
- `timestamp` (number): Response timestamp
- `conversationId` (string | null): Conversation ID

### `streamMessage` (HTTP Function)
Streams AI responses using Server-Sent Events (SSE).

**Request:**
- Method: POST
- Headers: `Authorization: Bearer <firebase-id-token>`
- Body: `{ message, provider, history }`

**Response:**
- Content-Type: `text/event-stream`
- Streams chunks as they arrive

### `checkUserQuota` (Callable Function)
Checks the user's remaining daily quota.

**Returns:**
- `used` (number): Messages used today
- `limit` (number): Daily limit (50 for free tier)
- `remaining` (number): Messages remaining
- `date` (string): Current date

## Quota System

Free tier users get **50 messages per day**. Usage is tracked in Firestore:

- Collection: `usage_daily`
- Document: `{userId}_{date}`
- Fields: `count`, `userId`, `date`, `lastUpdated`

## Local Testing

Run functions locally using the Firebase emulator:

```bash
npm run serve
```

Then update your Flutter app to use the local emulator:

```dart
// In lib/injection_container.dart after Firebase.initializeApp()
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

## Logs

View function logs:

```bash
firebase functions:log
```

Or view logs for a specific function:

```bash
firebase functions:log --only sendMessage
```

## Cost Estimates

### Firebase Free Tier (Spark Plan)
- ✅ 2M function invocations/month
- ✅ 400K GB-seconds/month
- ✅ 200K CPU-seconds/month

### Gemini API Free Tier
- ✅ 15 requests per minute
- ✅ 1,500 requests per day
- ✅ 1M tokens per month

**For < 100 users:** Completely FREE!

### Upgrade to Blaze (Pay-as-you-go)
Only needed when you exceed free tier limits:
- Cloud Functions: $0.40/million invocations
- Gemini API: Still free tier!
- Firestore: $0.06/100K reads, $0.18/100K writes

## Troubleshooting

### "API key not configured"
Run: `firebase functions:config:get` to check if the key is set.
If empty, set it with: `firebase functions:config:set gemini.key="YOUR_KEY"`

### "Unauthenticated" error
Make sure the user is signed in with Firebase Auth before calling functions.

### "resource-exhausted" error
User has exceeded daily quota (50 messages). They can try again tomorrow.

### Build errors
If you see TypeScript errors, run:
```bash
npm run build
```

If errors persist, check `tsconfig.json` has `"skipLibCheck": true`.

## Environment Variables

For local development, create a `.env` file (gitignored):

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

For production, always use Firebase config:
```bash
firebase functions:config:set gemini.key="YOUR_KEY"
```

## Next Steps

1. Deploy the functions
2. Test from your Flutter app
3. Monitor usage in Firebase Console
4. Add Claude/OpenAI support (optional)
5. Implement premium tiers (optional)
