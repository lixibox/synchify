module Synchify
  class AppsController < UiController
    before_action :set_app, only: [ :show, :toggle_connection_state ]

    def index
      @apps             = App.order(created_at: :desc)
      @pending_requests = ConnectionRequest.active
    end

    def show
      @recent_logs               = @app.event_logs.recent.limit(10)
      @registered_handle_events  = Synchify.configuration.handle_events
      @registered_payload_events = Synchify.configuration.payload_events
    end

    def toggle_connection_state
      new_state = @app.active? ? "paused" : "active"
      @app.update!(connection_state: new_state)
      redirect_to synchify.app_path(@app.app_code), notice: "App #{new_state}."
    end

    private

    def set_app
      @app = App.find_by!(app_code: params[:app_code])
    end
  end
end
