module Synchify
  module Apps
    class SettingsController < UiController
      before_action :set_app

      def show
        @incoming_configs = @app.event_configs.incoming.order(:event_name)
        @registered_events = Synchify.configuration.handle_events
      end

      def update
        new_key = params[:api_key].to_s.strip
        if new_key.present?
          @app.update!(api_key: new_key)
          redirect_to synchify.app_path(@app.app_code), notice: "API key updated."
        else
          redirect_to synchify.app_path(@app.app_code), alert: "API key cannot be blank."
        end
      end

      def update_event
        config = @app.event_configs.incoming.find(params[:id])
        config.update!(state: params[:state])
        redirect_to synchify.app_setting_path(@app.app_code), notice: "Updated."
      end

      private

      def set_app
        @app = App.find_by!(app_code: params[:app_code])
      end
    end
  end
end
