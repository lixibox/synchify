# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Synchify** — a mountable Rails Engine for managing bi-directional integrations, webhooks, and event-driven communication between multiple Rails applications.

Generated via: `rails plugin new synchify --mountable`

## Commands

```bash
# Run tests
bundle exec rspec

# Run a single spec
bundle exec rspec spec/path/to/file_spec.rb

# Run the dummy app
cd spec/dummy && rails server

# Run migrations on dummy app
cd spec/dummy && rails db:migrate

# Generate engine migrations
rails generate migration CreateSynchifyApps --engine synchify
```

## Architecture

### Engine Structure

- `lib/synchify/engine.rb` — Engine config, initializer DSL (`config.app_name`, `config.handle_events`, `config.payload_events`, `config.secret_key`)
- `app/models/synchify/` — Core models (see Data Models below)
- `app/controllers/synchify/` — Two controller namespaces: UI (`settings`, `apps`) and API (`connect`, `hooks`)
- `app/services/synchify/` — Business logic for handshake, event dispatch, signature verification
- `config/routes.rb` — Two distinct route groups: UI (host-app auth) and API (engine auth via API keys)

### Two Authorization Layers

1. **UI routes** (`/synchify/settings`, `/synchify/apps/*`) — Host app controls auth; engine provides a hook (e.g., `before_action` override)
2. **API routes** (`/synchify/connect`, `/synchify/apps/:app_code/hooks`) — Engine handles auth via `X-Synchify-Signature` HMAC-SHA256 + `api_key`
3. **Public routes** (`/synchify/health`, `/synchify/openapi.json`) — No auth; health returns engine status + DB connectivity; openapi.json serves the OpenAPI 3.1 spec memoized at engine boot (`@openapi_spec ||= generate_spec`), reset on every deploy/restart

### Data Models

| Model | Key fields |
|---|---|
| `Synchify::App` | `app_code` (unique slug), `api_key` (encrypted), `secret_token` (encrypted), `app_url`, `status` enum, `connection_state` enum |
| `Synchify::EventConfig` | `app_id`, `direction` enum (`incoming`/`outgoing`), `event_name`, `state` enum |
| `Synchify::EventLog` | `app_id`, `direction` enum, `event_name`, `event_id` (dedup), `payload` JSON, `request_id` |
| `Synchify::ConnectionRequest` | `requester_info` JSON, `request_key`, `status` enum, `expires_at` |

Sensitive fields (`api_key`, `secret_token`) use `ActiveRecord::Encryption`.

### Handshake Flow (A↔B)

System B initiates → sends `request_key` + `api_key` + optional `app_url` to System A's `/synchify/connect` → System A validates `request_key`, rotates it immediately, creates `ConnectionRequest` (status: `pending`) → Admin approves/rejects → if `app_url` present, System A POSTs callback with `verify_key` (request_key encrypted by secret) → System B verifies, updates local `App` record.

### Event Processing

Incoming events hit `/synchify/apps/:app_code/hooks` → engine verifies HMAC signature + timestamp → checks `EventConfig` (incoming direction) state (drops if `paused`/`disabled`) → dispatches to host-app service class defined in config → logs to `EventLog`.

### Security Schemes (OpenAPI `securitySchemes`)

- `X-Synchify-Signature` — `http` scheme, HMAC-SHA256 over payload + timestamp
- `X-Synchify-Timestamp` — Unix timestamp; reject if >5 min skew (replay attack prevention)
- `X-Api-Key` — `apiKey` scheme (header), per-app key for inter-app requests
- `X-Synchify-Event-ID` — deduplication via `EventLog`

### Error Responses

All API errors use RFC 7807 Problem Details: `type`, `title`, `status`, `detail`.

## Configuration DSL (Host App Initializer)

```ruby
Synchify.configure do |config|
  config.app_name = "CRM System"
  config.app_code = "crm_01"
  config.secret_key = ENV["SYNCHIFY_SECRET_KEY"]

  config.handle_event 'user.created' do
    Users::CreatedHandler
  end

  config.payload_event 'order.placed' do
    Orders::PlacedPayload
  end
end
```

**Incoming events** — block returns the handler class; engine calls `klass.new(payload).handle`. Class in `app/synchify/handlers/` (autoload root):

```ruby
# app/synchify/handlers/purchase_shipments/completed_handler.rb
module PurchaseShipments
  class CompletedHandler
  # Optional — shown in dashboard and OpenAPI spec
  def self.description
    "Handles inbound shipment completion"
  end

  # Required — describes the incoming payload schema
  def self.params_schema
    {
      "type"       => "object",
      "required"   => ["shipment_id", "status"],
      "properties" => {
        "shipment_id" => { "type" => "integer" },
        "status"      => { "type" => "string" }
      }
    }
  end

  # Required — describes the response schema returned to the sender
  def self.response_schema
    {
      "type"       => "object",
      "properties" => { "success" => { "type" => "boolean" } }
    }
  end

  def initialize(payload)
    @payload = payload
  end

  def handle
      # process @payload
    end
  end
end
```

**Outgoing events** — block returns the payload class; caller instantiates with domain object. Class in `app/synchify/payloads/` (autoload root):

```ruby
# app/synchify/payloads/purchase_orders/created_payload.rb
module PurchaseOrders
  class CreatedPayload
    # Describes the outgoing payload structure (used in OpenAPI spec)
    def self.schema
      {
        "type"       => "object",
        "required"   => ["order_id"],
        "properties" => {
          "order_id" => { "type" => "integer" },
          "status"   => { "type" => "string" }
        }
      }
    end

    def initialize(order)
      @order = order
    end

    def to_h
      { order_id: @order.id, status: @order.status }
    end
  end
end
```

Dispatch from anywhere in the host app:

```ruby
definition = Synchify.configuration.payload_events["order.placed"]
payload    = definition.klass.new(order)   # returns the payload builder object
```

## Implementation Phases

See `PLAN.md` for full spec. Order: Engine scaffolding → API + logging → state/pub-sub → UI dashboard → tests + dummy app.
