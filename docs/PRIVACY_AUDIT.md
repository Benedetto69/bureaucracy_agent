# Privacy Audit (GDPR ready)

Data: 2026-01-26
Scope: Bureaucracy · Analyzer (iOS app + backend FastAPI)

## 1. Data flow map (per feature)
| Feature | Data in | Processing | Destination | Retention |
| --- | --- | --- | --- | --- |
| Manual analysis | Text + metadata (case code, jurisdiction, amount, date) | Client -> API | Backend `/analyze` | Only for response; logs kept for limited time (suggested 30 days) |
| OCR (iOS) | Image from camera/photo | On-device OCR | Local only | Image not sent to server |
| Document draft | Issue list + actions | Client -> API | Backend `/generate-document` | Only for response; logs kept for limited time |
| History | Drafts + metadata | Local storage | SharedPreferences | Until user deletes or uninstalls |
| Purchases | Product IDs + entitlement | StoreKit (Apple) | Device only | Until user cancels; no server sync |

## 2. Data inventory
- User content: case text, OCR extracted text, metadata (case code, jurisdiction, amount, date).
- Identifiers: optional case code (should not be personal data).
- Purchases: entitlement status from App Store (no card data stored).
- StoreKit applicationUserName: uses the case code (avoid personal data).
- Technical: request_id, status code, document_id (server logs).

## 3. Third-party / SDKs
- Apple App Store / StoreKit: in-app purchases.
- image_picker: camera/photo library access.
- shared_preferences: local storage.
- http + uuid: network calls + request IDs.

## 4. Data minimization
- UI labels encourage a case code (no personal names/emails/phones).
- Only required fields are sent to the backend.

## 5. Retention
- Local: history kept until user deletes or uninstalls.
- Server: process only; keep technical logs for a limited window (suggested 30 days).

## 6. Gaps / follow-ups
- Add a public privacy contact email before publishing.
- Define log retention in production and document the exact period.
- Consider encrypting local history if sensitive data is stored.
