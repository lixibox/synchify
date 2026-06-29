# Synchify

Mountable Rails Engine for bi-directional webhook integrations between Rails apps.

Mount Synchify in any Rails application to get a full integration layer: handshake-based app registration, HMAC-signed webhook delivery, event routing, deduplication, and a built-in dashboard — without writing any of the plumbing yourself.

## Features

- **Handshake flow** — two apps exchange keys through an admin-approved request/callback cycle
- **Signed webhooks** — HMAC-SHA256 over payload + timestamp; replay protection via 5-minute window
- **Event routing** — declare `handle_event` (incoming) and `payload_event` (outgoing) in an initializer; engine dispatches automatically
- **Background delivery** — outgoing events queued via `Synchify::TriggerEvent.call` → `DeliverEventJob`
- **Deduplication** — `X-Synchify-Event-ID` checked against `EventLog` before processing
- **OpenAPI spec** — auto-generated at `/synchify/openapi.json` from your event definitions
- **Dashboard UI** — `/synchify` — manage apps, review pending requests, monitor event logs

## Installation

Add to your Gemfile:

```ruby
gem "synchify"
```

Mount the engine in `config/routes.rb`:

```ruby
mount Synchify::Engine, at: "/synchify"
```

Run the installer:

```bash
bundle exec rails generate synchify:init
bundle exec rails db:migrate
```

## Configuration

```ruby
# config/initializers/synchify.rb
Synchify.configure do |config|
  config.app_name   = "CRM System"
  config.app_code   = "crm_01"
  config.secret_key = ENV["SYNCHIFY_SECRET_KEY"]

  # Incoming — engine calls Handler.new(payload).handle
  config.handle_event "user.created" do
    Users::CreatedHandler
  end

  # Outgoing — caller builds payload from a domain object
  config.payload_event "order.placed" do
    Orders::PlacedPayload
  end
end
```

## Triggering outgoing events

```ruby
Synchify::TriggerEvent.call("order.placed", order)
```

Finds all approved, active apps with a matching outgoing `EventConfig` and enqueues `DeliverEventJob` for each.

## Handlers and payloads

```ruby
# app/synchify/handlers/users/created_handler.rb
module Users
  class CreatedHandler < Synchify::HandleEvent
    description "Creates a user from an incoming event"

    params do
      required "id",       type: "integer"
      optional "currency", type: "string"
    end

    payload_validate :currency, in: -> { Buyer::ProductOrder.currencies.keys }

    def handle
      User.create!(id: payload["id"])
    end
  end
end

# app/synchify/payloads/orders/placed_payload.rb
module Orders
  class PlacedPayload
    def self.schema = { "type" => "object", "required" => ["order_id"], "properties" => { "order_id" => { "type" => "integer" } } }

    def initialize(order) = @order = order
    def to_h = { order_id: @order.id, status: @order.status }
  end
end
```

## Payload validation

Declare business-logic validations on handler classes with `payload_validate`. Runs after JSON schema checks — invalid payloads return 422 before `handle` is called.

```ruby
class Orders::CreatedHandler < Synchify::HandleEvent
  payload_validate :currency, in: -> { Buyer::ProductOrder.currencies.keys }
  payload_validate :status,   in: %w[pending confirmed cancelled]
end
```

`in:` accepts a lambda (evaluated lazily at validation time) or a plain array. Fields with `nil` values skip the check — use `params` schema `required` to enforce presence.

## Security

| Header | Purpose |
|---|---|
| `X-Synchify-Signature` | HMAC-SHA256 over `"#{timestamp}\n#{body}"` |
| `X-Synchify-Timestamp` | Unix timestamp — requests older than 5 min rejected |
| `X-Synchify-Event-ID` | UUID for deduplication |
| `X-Synchify-App-Code` | Identifies the sender |

## License

[MIT License](https://opensource.org/licenses/MIT).
