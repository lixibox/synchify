module Synchify
  class HealthController < ApiController
    def show
      render json: {
        status:        "ok",
        engine:        "synchify",
        version:       Synchify::VERSION,
        configuration: config_summary,
        database:      database_status
      }
    end

    private

    def config_summary
      {
        app_name:        Synchify.configuration.app_name,
        app_code:        Synchify.configuration.app_code,
        handle_events:  Synchify.configuration.handle_events.keys,
        payload_events: Synchify.configuration.payload_events.keys
      }
    end

    def database_status
      ActiveRecord::Base.connection.active? ? "ok" : "error"
    rescue => e
      "error: #{e.message}"
    end
  end
end
