module Synchify
  module Apps
    class MonitorController < UiController
      before_action :set_app

      def show
        @event_names = @app.event_logs.distinct.order(:event_name).pluck(:event_name)
        @logs = @app.event_logs
                     .order(created_at: :desc)
                     .limit(50)
        @logs = @logs.where(direction: params[:direction]) if params[:direction].present?
        @logs = @logs.where(event_name: params[:event_name]) if params[:event_name].present?
      end

      private

      def set_app
        @app = App.find_by!(app_code: params[:app_code])
      end
    end
  end
end
