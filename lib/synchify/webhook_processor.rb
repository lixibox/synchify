module Synchify
  class WebhookProcessor
    Result = Struct.new(:status, :body, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(app:, event_name:, event_id:, payload:, request_id:)
      @app        = app
      @event_name = event_name.to_s
      @event_id   = event_id
      @payload    = payload || {}
      @request_id = request_id
    end

    def call
      event_config = @app.event_configs.incoming.find_by(event_name: @event_name)

      unless event_config&.accepting?
        log!(422, "Event: Disabled")
        return error(:unprocessable_entity, "event-disabled", "Event Disabled", 422)
      end

      definition = Synchify.configuration.handle_events[@event_name]

      unless definition
        log!(404, "Event: Not Registered")
        return error(:not_found, "event-not-registered", "Event Not Registered", 404)
      end

      validator = PayloadValidator.new(event_name: @event_name, payload: @payload)
      unless validator.valid?
        log!(422, "Payload: Invalid")
        return error(:unprocessable_entity, "invalid-payload", "Invalid Payload", 422, detail: validator.errors.join(", "))
      end

      handler = definition.klass.handle(@payload)
      log!(200)
      Result.new(status: :ok, body: handler.response || { success: true })
    rescue => e
      log!(500, e.to_s)
      raise
    end

    private

    def log!(status_code, message = nil)
      EventLog.create!(
        app:         @app,
        direction:   :incoming,
        event_name:  @event_name,
        event_id:    @event_id,
        payload:     @payload,
        status_code: status_code,
        request_id:  @request_id,
        metadata: {
          error: message || status_code
        }
      )
    end

    def error(status, type_slug, title, code, detail: nil)
      body = { type: "synchify.errors.#{type_slug}", title: title, status: code }
      body[:detail] = detail if detail
      Result.new(status: status, body: body)
    end
  end
end
