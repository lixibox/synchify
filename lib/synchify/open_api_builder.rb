module Synchify
  class OpenApiBuilder
    def self.spec
      @spec ||= new.build
    end

    def self.reset!
      @spec = nil
    end

    def build
      {
        "openapi"    => "3.1.0",
        "info"       => info,
        "webhooks"   => build_webhooks,
        "components" => { "securitySchemes" => security_schemes }
      }
    end

    private

    def info
      {
        "title"   => "#{Synchify.configuration.app_name} Webhook API",
        "version" => "1.0.0"
      }
    end

    def build_webhooks
      webhooks = {}

      Synchify.configuration.handle_events.each do |name, klass|
        webhooks[name] = webhook_entry(name, klass)
      end

      Synchify.configuration.payload_events.each do |name, klass|
        webhooks[name] = webhook_entry(name, klass)
      end

      webhooks
    end

    def webhook_entry(name, klass)
      {
        "post" => {
          "summary"     => klass.description || name,
          "requestBody" => {
            "required" => true,
            "content"  => {
              "application/json" => {
                "schema" => event_envelope_schema(name, klass.params_schema)
              }
            }
          },
          "responses"   => responses(klass.response_schema),
          "security"    => [ { "ApiKey" => [], "HmacSignature" => [] } ]
        }
      }
    end

    def event_envelope_schema(event_name, params_schema)
      {
        "type"       => "object",
        "required"   => [ "event", "payload" ],
        "properties" => {
          "event"   => {
            "type"       => "object",
            "required"   => [ "id", "name", "timestamp" ],
            "properties" => {
              "id"        => { "type" => "string" },
              "name"      => { "type" => "string", "example" => event_name },
              "timestamp" => { "type" => "string", "format" => "date-time" }
            }
          },
          "payload" => params_schema || { "type" => "object" }
        }
      }
    end

    def responses(response_schema)
      {
        "200" => {
          "description" => "Event processed",
          "content"     => {
            "application/json" => {
              "schema" => response_schema || { "type" => "object" }
            }
          }
        },
        "401" => { "description" => "Unauthorized" },
        "409" => { "description" => "Duplicate Event" },
        "422" => { "description" => "Event Disabled or Invalid Payload" }
      }
    end

    def security_schemes
      {
        "ApiKey"        => { "type" => "apiKey", "in" => "header", "name" => "X-Api-Key" },
        "HmacSignature" => { "type" => "http", "scheme" => "bearer", "bearerFormat" => "HMAC-SHA256" }
      }
    end
  end
end
