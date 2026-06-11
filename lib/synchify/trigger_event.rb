module Synchify
  class TriggerEvent
    def self.call(event_name, object)
      new(event_name, object).call
    end

    def initialize(event_name, object)
      @event_name = event_name.to_s
      @object     = object
    end

    def call
      definition = Synchify.configuration.payload_events[@event_name]
      raise ArgumentError, "No payload_event registered for '#{@event_name}'" unless definition

      payload = definition.klass.new(@object).to_h

      target_apps.each do |app|
        DeliverEventJob.perform_later(app.id, @event_name, payload)
      end
    end

    private

    def target_apps
      App.approved.active
         .joins(:event_configs)
         .where(
           event_configs: {
             direction:  "outgoing",
             event_name: @event_name,
             state:      "active"
           }
         )
         .distinct
    end
  end
end
