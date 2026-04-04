# OAuth & External API Integration — Reference

## Overview

Figma plugins can integrate with external APIs, but the sandbox architecture requires a specific approach. The main thread **cannot** make network requests — all external communication must happen in the **UI thread** (iframe).

## Architecture

```
┌─────────────────┐    postMessage    ┌─────────────────┐    HTTPS    ┌────────────────┐
│   Main Thread   │ ←──────────────→  │    UI Thread     │ ──────────→│  Your Backend  │
│   (code.ts)     │                   │   (ui.html)      │            │   Server       │
│                 │                   │                  │            │                │
│ figma.*         │                   │ fetch()          │            │ OAuth dance    │
│ clientStorage   │                   │ window.open()    │            │ Token storage  │
│ No network!     │                   │ DOM manipulation │            │ API proxy      │
└─────────────────┘                   └─────────────────┘            └────────────────┘
```

## Making API Calls from the UI

### Simple REST API Call

```typescript
// ui.ts — Make API calls from the UI thread
async function fetchData(endpoint: string) {
  try {
    const response = await fetch(`https://api.example.com/${endpoint}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    });
    const data = await response.json();
    
    // Send data back to main thread
    parent.postMessage({ pluginMessage: { type: 'api-data', data } }, '*');
  } catch (error) {
    parent.postMessage({ pluginMessage: { type: 'api-error', error: error.message } }, '*');
  }
}
```

### Handling in Main Thread
```typescript
// code.ts
figma.ui.onmessage = async (msg) => {
  if (msg.type === 'api-data') {
    // Use the data from the external API
    createNodesFromData(msg.data);
  }
  if (msg.type === 'api-error') {
    figma.notify(`API Error: ${msg.error}`, { error: true });
  }
};
```

## OAuth Authentication Flow

Since plugins run in a sandbox with no `window.opener` support, you need a polling-based flow:

### Step 1: Backend Setup
Your server needs these endpoints:
- `POST /auth/session` — Create a session with read/write keys
- `GET /auth/callback` — OAuth callback handler
- `GET /auth/status/:readKey` — Poll endpoint for auth completion

### Step 2: Plugin UI Implementation

```typescript
// ui.ts
let pollingInterval: number | null = null;

async function startOAuth() {
  // 1. Get session keys from your server
  const session = await fetch('https://your-server.com/auth/session', {
    method: 'POST',
  }).then(r => r.json());

  const { readKey, writeKey } = session;

  // 2. Open OAuth window in the browser
  const authUrl = `https://your-server.com/auth/start?writeKey=${writeKey}`;
  window.open(authUrl, '_blank');

  // 3. Poll for completion
  pollingInterval = setInterval(async () => {
    const status = await fetch(
      `https://your-server.com/auth/status/${readKey}`
    ).then(r => r.json());

    if (status.authenticated) {
      clearInterval(pollingInterval!);
      
      // Send the token to the main thread for storage
      parent.postMessage({
        pluginMessage: {
          type: 'auth-complete',
          token: status.sessionToken,
        }
      }, '*');
    }
  }, 2000); // Poll every 2 seconds
}
```

### Step 3: Main Thread Token Storage

```typescript
// code.ts
figma.ui.onmessage = async (msg) => {
  if (msg.type === 'auth-complete') {
    // Store token persistently
    await figma.clientStorage.setAsync('auth-token', msg.token);
    figma.notify('Connected successfully! ✅');
  }

  if (msg.type === 'check-auth') {
    const token = await figma.clientStorage.getAsync('auth-token');
    figma.ui.postMessage({ type: 'auth-status', token });
  }
};
```

### Step 4: Check Auth on Plugin Launch

```typescript
// code.ts — On startup
figma.showUI(__html__, { width: 400, height: 500, themeColors: true });

// Send stored token to UI
const storedToken = await figma.clientStorage.getAsync('auth-token');
figma.ui.postMessage({ type: 'auth-status', token: storedToken });
```

```typescript
// ui.ts — Handle stored token
onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (msg.type === 'auth-status') {
    if (msg.token) {
      showAuthenticatedUI();
      accessToken = msg.token;
    } else {
      showLoginButton();
    }
  }
};
```

## Security Best Practices

1. **Use PKCE** (Proof Key for Code Exchange) for all OAuth flows
2. **Never hardcode secrets** in plugin code — it's inspectable
3. **Use HTTPS only** for all external requests
4. **Restrict domains** in `manifest.json` `networkAccess`
5. **Minimize data sent** to your backend from Figma
6. **Provide a privacy policy** if processing user data
7. **Store tokens in `clientStorage`** (isolated per-user, per-plugin)

## Manifest Configuration

```json
{
  "networkAccess": {
    "allowedDomains": [
      "your-server.com",
      "api.external-service.com"
    ],
    "devAllowedDomains": [
      "http://localhost:3000"
    ]
  }
}
```
