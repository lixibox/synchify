module Synchify
  class EventConfigSyncer
    def self.sync(app)
      new(app).sync
    end

    def initialize(app)
      @app = app
    end

    def sync
      sync_direction(:handle_events,  :incoming)
      sync_direction(:payload_events, :outgoing)
    end

    private

    def sync_direction(config_key, direction)
      Synchify.configuration.public_send(config_key).each_key do |event_name|
        @app.event_configs.find_or_create_by!(direction: direction, event_name: event_name)
      end
    end
  end
end
