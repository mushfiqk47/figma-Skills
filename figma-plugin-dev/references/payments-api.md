# Figma Payments API — Monetization Reference

## Overview

The Payments API lets you monetize your Figma plugin with a freemium model. Figma requires that plugins using Payments still provide free features — you cannot lock the entire plugin behind a paywall.

## Manifest Setup

Add `"payments"` to your permissions:
```json
{
  "name": "My Premium Plugin",
  "id": "...",
  "api": "1.0.0",
  "main": "code.js",
  "ui": "ui.html",
  "permissions": ["payments"]
}
```

## Checking Payment Status

```typescript
// Check if user has paid
const status = figma.payments.status;

switch (status.type) {
  case 'PAID':
    // Full access to premium features
    enablePremiumFeatures();
    break;
  case 'UNPAID':
    // Show free tier or upgrade prompts
    showFreeTier();
    break;
  case 'NOT_SUPPORTED':
    // Error occurred — treat as unpaid
    showFreeTier();
    break;
}
```

## Triggering Checkout

```typescript
async function promptUpgrade() {
  try {
    await figma.payments.initiateCheckoutAsync({
      interstitial: 'PAID_FEATURE'
    });
    // After checkout completes, re-check status
    if (figma.payments.status.type === 'PAID') {
      figma.notify('Welcome to Premium! 🎉');
      enablePremiumFeatures();
    }
  } catch (err) {
    figma.notify('Checkout was cancelled', { error: true });
  }
}
```

## Development Testing

```typescript
// Simulate paid status during development
figma.payments.setPaymentStatusInDevelopment({ type: 'PAID' });

// Simulate unpaid status
figma.payments.setPaymentStatusInDevelopment({ type: 'UNPAID' });
```

> **Note:** This only works in development mode and has no effect in published plugins.

## Server-Side Verification

If you need to verify payment status on your backend:

```typescript
// Get a payment token to send to your server
const token = await figma.payments.getPluginPaymentTokenAsync();

// Send to your backend
figma.ui.postMessage({
  type: 'verify-payment',
  token: token
});
```

Your server can then verify using the [Figma Payments REST API](https://www.figma.com/developers/api#payments).

## Freemium Pattern Example

```typescript
const PREMIUM_FEATURES = ['batch-export', 'ai-suggestions', 'custom-themes'];

function isFeaturePremium(feature: string): boolean {
  return PREMIUM_FEATURES.includes(feature);
}

async function useFeature(feature: string) {
  if (isFeaturePremium(feature)) {
    if (figma.payments.status.type !== 'PAID') {
      // Show upgrade prompt in UI
      figma.ui.postMessage({
        type: 'show-upgrade',
        feature: feature
      });
      return;
    }
  }
  
  // Execute the feature
  executeFeature(feature);
}
```

## Alternative: External Payment Providers

You can also use third-party payment services (Stripe, Lemon Squeezy, Gumroad) instead of Figma's native Payments:

1. **Redirect to external site** for payment (don't embed payment forms in plugin UI)
2. **Issue license keys** after purchase
3. **Validate keys** via your backend when the plugin starts
4. **Store status** in `figma.clientStorage` to avoid re-validation every launch

```typescript
// Example: License key validation
figma.ui.onmessage = async (msg) => {
  if (msg.type === 'validate-license') {
    const response = await validateWithServer(msg.licenseKey);
    if (response.valid) {
      await figma.clientStorage.setAsync('license', {
        key: msg.licenseKey,
        validUntil: response.expiresAt
      });
    }
  }
};
```
