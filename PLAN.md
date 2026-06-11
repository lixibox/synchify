# Rails Engine: Synchify Integration Manager

A Rails Engine designed to manage integrations, webhooks, and event-driven communication between multiple systems.

## 1. Overview
Synchify acts as a central hub for managing how a Rails application interacts with external apps and other internal systems. It provides a standardized way to handle incoming webhooks, outgoing events, and connection approvals. The engine adheres to **OpenAPI 3.1** conventions — webhook events are schema-first, and a live spec is auto-generated and served for connected apps to consume.

## 2. Core Components

### A. Engine Configuration (Initialization)
Synchify is configured via a Rails initializer.
- **Host App Identity:** Define `AppName` and `AppCode` for the current Rails app (used in handshake payloads).
- **Incoming Events Definition:** Register via a block that returns the handler class: `config.handle_event 'user.created' do Users::CreatedHandler end`. Engine calls `klass.new(payload).handle`. Class defines `params_schema`, `response_schema` (required) and `description` (optional) as class methods.
- **Outgoing Events Definition:** Register via a block that returns the payload class: `config.payload_event 'po.created' do PurchaseOrders::CreatedPayload end`. Class defines `schema` as a class method for OpenAPI spec generation.

### B. Connected Apps Management
- **App Registry:** A registry of all external systems/apps integrated with the app.
- **Bi-directional Capability:** By default, all connected apps support both incoming and outgoing events. Capability is managed by enabling/disabling specific events in the settings.
- **Security & Authentication:** 
  - **Root Security:** All management access is protected by a configured `secret_key`.
  - **Inter-App Security:** Requests between Rails apps using this engine are verified via **API Keys**.
  - **Storage:** API keys are stored in the database using encryption (e.g., `ActiveRecord::Encryption`).
  - **Request Keys:** One-time use, daily rotating keys for initiating new connections.

### C. Webhooks Management
- **Event Catalog:** Webhook events defined as OpenAPI 3.1 `webhooks` entries — named, schema-first, derived from registered event classes.
- **Subscription Model:** Allow external apps to subscribe to specific event names.
- **Payload Schema:** Defined in codebase via event class DSL (inline block, YAML file, or schema class). NOT stored in DB. `ParamsBuilder` (`requires`/`optional`) and `ResponseBuilder` (`property`) compile to JSON Schema at runtime.
- **Spec Generation:** Engine auto-generates and serves a live OpenAPI 3.1 spec (`/synchify/openapi.json`) from all registered incoming/outgoing events.

### D. Logging & Auditing
- **Hook Logs:** Record every incoming and outgoing event call.
- **Attributes:** Timestamp, Payload, Headers, Response Code, Response Body, and Processing Time.
- **Traceability:** Unique `request_id` to trace an event from reception to internal processing.

### E. State & Event Control
- **Per-Event Toggle:** Use Rails `enum` to control the status of specific events globally or per app.
- **States:** `active`, `paused`, `deprecated`, `disabled`.
- **Logic:** If an event is `paused` or `disabled`, incoming events for that name are dropped or queued without processing.

### F. Approval Workflow (System A & B Handshake)
1. **Initiation (System A):** Admin goes to `/synchify/settings` and copies the **Connect Info** — a single string in the format `https://host/synchify/connect?key=REQUEST_KEY`.
2. **Request (System B):** Admin clicks "Connect New App" and pastes System A's Connect Info.
   - System B parses the URL and `key` query param, then POSTs to System A with: `AppName`, `AppCode`, `api_key`, `request_key`, and an **optional `app_url`** (System B's own `/synchify/connect` callback URL).
   - **Verification:** System A validates that the incoming `request_key` matches its current active key. If invalid, the request is rejected immediately.
   - **System A Response:** Returns `{ received: true, app_name, app_code }` so System B knows System A's identity.
   - **System B Action:** Creates/upserts a local `Synchify::App` record and `ConnectionRequest` for System A (status `requested`) using the returned `app_name`/`app_code`.
3. **Rotation (System A):** Immediately after a valid request is received, System A generates a new `RequestKey`.
4. **Review (System A):** Admin reviews the pending `ConnectionRequest` in `/synchify/apps`.
5. **Callback Confirmation (System A -> System B):**
   - **Condition:** This step is only performed if `app_url` was provided in Step 2.
   - **On Approve:** System A creates a `Synchify::App` record, generates its own `api_key`, and sends a **POST** callback to System B's provided `app_url` with status `approved`.
   - **Payload:** System A's metadata, its own `app_url`, and a `verify_key` (the `request_key` encrypted by secret).
   - **On Reject:** System A sends a callback with status `rejected` (also including the `verify_key`).
6. **Finalization (System B):** If a callback is received:
   - **Verification:** System B decrypts and verifies the `verify_key` matches its original `request_key`.
   - **On Approved:** Updates the local `Synchify::App` record for System A: saves System A's `app_url` and updates status to `approved`.
   - **On Rejected:** Updates the local `Synchify::App` status to `rejected`.
7. **Management:** Both systems can now exchange events using their respective `app_url` endpoints (if approved).

## 3. Interfaces & Routes

The engine provides two distinct route namespaces with different authorization strategies.

### A. UI Dashboard (Management)
- **Authorization:** Handled by the **Host Rails Application**.
- **Path:** `/synchify/settings` - View host configuration and active `RequestKey`.
- **Path:** `/synchify/apps` - List all registered Apps and their status (`requested`, `approved`, `rejected`).
- **Path:** `/synchify/apps/:app_code` - Detailed view of a specific App.
- **Path:** `/synchify/apps/:app_code/setting` - Manage **Incoming Events** and security.
- **Path:** `/synchify/apps/:app_code/events` - Manage **Outgoing Events**.
- **Path:** `/synchify/apps/:app_code/monitor` - Monitor logs for all events.

### B. API Endpoint (Internal Communication)
- **Authorization:** Handled by the **Synchify Engine** using API Keys and Secret Tokens.
- **Handshake Path:** `/synchify/connect` - Handles initial `ConnectionRequest` and callbacks.
- **Event Path:** `/synchify/apps/:app_code/hooks` - Main entry point for event traffic.

### C. Public Endpoints (No Auth)
- **Health Path:** `/synchify/health` - Engine status, config presence, DB connectivity.
- **Spec Path:** `/synchify/openapi.json` - OpenAPI 3.1 spec generated once per deploy, memoized at engine boot via class-level `@openapi_spec ||= generate_spec`. Cleared on app restart (every deploy).

## 4. Data Model Strategy

### Synchify::App
- `name`: String
- `app_code`: String (Unique slug)
- `api_key`: String (Encrypted)
- `secret_token`: String (Encrypted)
- `app_url`: String (The Hook URL for this app)
- `status`: Enum (`requested`, `approved`, `rejected`)
- `connection_state`: Enum (`active`, `paused`, `disabled`)

### Synchify::EventConfig
- `app_id`: Integer (Foreign Key)
- `direction`: Enum (`incoming`, `outgoing`)
- `event_name`: String
- `state`: Enum (`active`, `paused`, `disabled`)

### Synchify::EventLog
- `app_id`: Integer (Foreign Key)
- `direction`: Enum (`incoming`, `outgoing`)
- `event_name`: String
- `event_id`: String (For de-duplication)
- `payload`: JSON
- `status_code`: Integer
- `metadata`: JSON
- `request_id`: String (Traceability)

### Synchify::ConnectionRequest
- `requester_info`: JSON (AppName, AppCode, AppUrl, etc.)
- `request_key`: String (Unique request token)
- `status`: Enum (`pending`, `approved`, `rejected`)
- `expires_at`: DateTime (Default 7 days from creation)

## 5. Payload & Security Specifications

### A. Handshake Payloads

**0. Connect Info (copied from System A's Settings page)**
```
https://system-a.example.com/synchify/connect?key=TEMP_RANDOM_KEY
```
System A copies this single string. System B pastes it into "Connect New App" — engine parses URL and `key` query param automatically.

**1. Connection Request (System B -> System A)**
```json
{
  "request_key": "TEMP_RANDOM_KEY",
  "app_name": "Billing System",
  "app_code": "billing_01",
  "app_url": "https://billing.example.com/synchify/connect",
  "api_key": "B_GENERATED_KEY_FOR_A"
}
// Note: app_url is optional. If blank, Step 5 (Callback) is skipped.
```
**2. Connection Response (System A -> System B)**
```json
{
  "received": true,
  "app_name": "CRM System",
  "app_code": "crm_01"
}
```
System B uses `app_name`/`app_code` to upsert a local `Synchify::App` record and `ConnectionRequest`.

**3. Approval Callback (System A -> System B)**
```json
{
  "status": "approved",
  "app_name": "CRM System",
  "app_code": "crm_01",
  "app_url": "https://crm.example.com/synchify/connect",
  "api_key": "A_GENERATED_KEY_FOR_B",
  "verify_key": "ENCRYPTED_VALUE"
}
```

### B. Event Payload (General)
Sent to `/synchify/apps/:app_code/hooks`
```json
{
  "event": {
    "id": "evt_83429ac2",
    "name": "user.created",
    "timestamp": "2026-06-04T10:00:00Z"
  },
  "payload": {
    "user_id": 123,
    "email": "user@example.com"
  }
}
```

### C. Security Schemes (OpenAPI `securitySchemes`)
- `X-Synchify-Signature`: `http` scheme — HMAC-SHA256 signature over payload + timestamp.
- `X-Synchify-Timestamp`: Unix timestamp (replay attack prevention, reject if >5 min skew).
- `X-Api-Key`: `apiKey` scheme (header) — per-app API key for inter-app requests.
- `X-Synchify-Event-ID`: Unique ID for de-duplication via `EventLog`.

### D. Error Response (RFC 7807 Problem Details)
All API error responses use a consistent shape:
```json
{
  "type": "https://synchify.dev/errors/invalid-signature",
  "title": "Invalid Signature",
  "status": 401,
  "detail": "HMAC signature does not match payload."
}
```

## 6. Implementation Plan

### Phase 1: Engine Scaffolding ✅
- Generate the Rails Engine (`rails plugin new synchify --mountable`).
- Set up the database migrations for core models.
- Implement Configuration DSL with `Synchify::HandleEvent` / `PayloadEvent` base classes.
- Install generator (`rails g synchify:init`) — creates initializer, mounts engine, installs migrations.

### Phase 2: API & Logging ✅
- Implement `POST /synchify/apps/:app_code/hooks` route.
- Auth via `X-Api-Key`, signature via HMAC-SHA256 (`SignatureVerifier`), dedup via `X-Synchify-Event-ID`.
- `WebhookProcessor` — checks `EventConfig` (incoming) state, dispatches to event class `handle`, logs to `EventLog`.

### Phase 3: State, Webhooks & OpenAPI Spec ✅
- `EventConfigSyncer` — syncs registered events → `EventConfig` (incoming/outgoing) on app approve.
- `PayloadValidator` — validates required fields + types against `params_schema` from event class.
- `OpenApiBuilder` — memoized OpenAPI 3.1 spec; served at `GET /synchify/openapi.json`, reset on `reset_configuration!`.
- `GET /synchify/health` — engine status, config presence, DB connectivity.

### Phase 4: UI Dashboard ✅
- UI routes: settings, apps (index/show/approve/reject), app setting/events/monitor.
- `UiController` — hookable `synchify_authenticate!` for host app auth override.
- `RequestKeyManager` — daily-rotating key via Rails cache for handshake initiation.
- `ConnectController` + `HandshakeService` — full A↔B handshake: connection request, key rotation, approval callback with `verify_key` (HMAC-encrypted), MySQL/PostgreSQL-compatible.
- HAML views for all dashboard pages with event config state toggles and event log monitor.

### Phase 5: Testing & Integration
- Write RSpec tests for handshake workflow and event processing.
- Create a dummy app to verify the engine's integration capabilities.
