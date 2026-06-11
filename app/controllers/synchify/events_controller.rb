module Synchify
  class EventsController < UiController
    def index
      @handle_events  = Synchify.configuration.handle_events
      @payload_events = Synchify.configuration.payload_events
    end
  end
end
