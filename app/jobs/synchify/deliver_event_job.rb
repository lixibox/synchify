require "openssl"

module Synchify
  class DeliverEventJob < ApplicationJob
    queue_as :default

    def perform(app_id, event_name, payload)
      app = App.find(app_id)
      return unless app.active? && app.hook_url.present?

      event_id = SecureRandom.uuid
      result   = deliver!(app, event_id, event_name, payload)
      log_event(app, event_name, event_id, payload, result: result)
    rescue => e
      log_event(app, event_name, event_id, payload, error: e.message) rescue nil
      Rails.logger.error "[Synchify] DeliverEventJob failed app_id=#{app_id} event=#{event_name}: #{e.message}"
      raise
    end

    private

    def deliver!(app, event_id, event_name, payload)
      timestamp = Time.current.to_i
      body      = build_body(event_id, event_name, payload, timestamp)
      signature = OpenSSL::HMAC.hexdigest("SHA256", app.secret_token.to_s, "#{timestamp}\n#{body}")

      NetRequest.post(app.hook_url, body: body, headers: {
        "X-Synchify-Signature" => signature,
        "X-Synchify-Timestamp" => timestamp.to_s,
        "X-Synchify-Event-ID"  => event_id,
        "X-Synchify-App-Code"  => Synchify.configuration.app_code.to_s
      })
    end

    def build_body(event_id, event_name, payload, timestamp)
      { event: { id: event_id, name: event_name, timestamp: timestamp }, payload: payload }.to_json
    end

    def log_event(app, event_name, event_id, payload, result: nil, error: nil)
      EventLog.create!(
        app:         app,
        direction:   :outgoing,
        event_name:  event_name,
        event_id:    event_id,
        payload:     payload,
        status_code: result&.code,
        metadata:    result ? { "response_body" => result.body } : { "error" => error },
        request_id:  SecureRandom.uuid
      )
    end
  end
end
