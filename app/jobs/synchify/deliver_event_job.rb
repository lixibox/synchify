require "openssl"

module Synchify
  class DeliverEventJob < ApplicationJob
    queue_as :default

    def perform(app_id, event_name, payload)
      app = App.find(app_id)
      return unless app.active? && app.hook_url.present?

      timestamp = Time.current.to_i
      event_id  = SecureRandom.uuid
      body      = {
        event:   { id: event_id, name: event_name, timestamp: timestamp },
        payload: payload
      }.to_json

      signature = OpenSSL::HMAC.hexdigest("SHA256", app.secret_token.to_s, "#{timestamp}\n#{body}")

      result = post!(app, body, signature, timestamp, event_id)

      EventLog.create!(
        app:         app,
        direction:   :outgoing,
        event_name:  event_name,
        event_id:    event_id,
        payload:     payload,
        status_code: result.code,
        request_id:  SecureRandom.uuid
      )
    rescue => e
      Rails.logger.error "[Synchify] DeliverEventJob failed app_id=#{app_id} event=#{event_name}: #{e.message}"
      raise
    end

    private

    def post!(app, body, signature, timestamp, event_id)
      NetRequest.post(app.hook_url, body: body, headers: {
        "X-Synchify-Signature" => signature,
        "X-Synchify-Timestamp" => timestamp.to_s,
        "X-Synchify-Event-ID"  => event_id,
        "X-Synchify-App-Code"  => Synchify.configuration.app_code.to_s
      })
    end
  end
end
