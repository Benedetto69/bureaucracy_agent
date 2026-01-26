# App Store Privacy Answers (summary)

This is a concise mapping for App Store Connect. Verify each answer before submission.

## Data collection
- User Content: YES (case description, OCR text, metadata such as jurisdiction/amount/date).
- Purchases: YES (entitlement status via StoreKit).
- Identifiers: NO (no account, no device ID stored by the app).
- Diagnostics: NO (no analytics or crash SDKs).

## Data use
- App functionality: YES (analysis + document draft).
- Analytics: NO.
- Advertising/marketing: NO.
- Third-party advertising: NO.

## Data linked to user
- Not linked to user identity (no account). If you later add accounts, update this.

## Tracking
- Tracking: NO.

## Notes
- Images are not sent to the server; OCR runs on-device on iOS.
- The server receives only text + metadata needed for analysis.
