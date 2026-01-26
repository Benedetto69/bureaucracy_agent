# DSAR Runbook (access / delete / export)

Use this runbook to handle GDPR data requests.

## 1. Intake
- Channel: privacy@tuodominio.com (replace with real email before launch).
- Acknowledge receipt within 7 days.

## 2. Verify request
- Ask for: case code (if provided), approximate date/time of analysis, and device platform.
- If no account exists, explain that data is stored locally on the device and only minimal logs exist on the server.

## 3. Data sources
- Client (local): drafts + metadata stored in SharedPreferences. User can export/delete in-app (Gestione dati).
- Server: technical logs (request_id, status, document_id) for a limited retention period.

## 4. Fulfilment
- Access/export: provide any server log entries that match the request_id or document_id (if retained).
- Deletion: remove matching log entries if still within retention window.
- Local data: instruct user to use in-app delete or uninstall.

## 5. Response timeline
- Target: within 30 days.

## 6. Record keeping
- Keep a minimal record of the request (date, type, outcome) without storing user content.
