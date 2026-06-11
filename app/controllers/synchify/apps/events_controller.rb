module Synchify
  module Apps
    class EventsController < UiController
      before_action :set_app

      def show
        @handle_events    = Synchify.configuration.handle_events
        @payload_events   = Synchify.configuration.payload_events
        @incoming_configs = @app.event_configs.incoming.index_by(&:event_name)
        @outgoing_configs = @app.event_configs.outgoing.index_by(&:event_name)
      end

      def update_event
        config = @app.event_configs.find(params[:id])
        config.update!(state: params[:state])
        redirect_to synchify.app_events_path(@app.app_code), notice: "Updated."
      end

      def toggle_event
        config = @app.event_configs.find_or_create_by!(
          direction: params[:direction],
          event_name: params[:event_name]
        )
        config.update!(state: params[:state])
        redirect_to synchify.app_events_path(@app.app_code), notice: "Updated."
      end

      private

      def set_app
        @app = App.find_by!(app_code: params[:app_code])
      end
    end
  end
end
