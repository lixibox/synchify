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

      def retry_log
        log = @app.event_logs.find(params[:log_id])
        if log.incoming?
          WebhookProcessor.call(
            app:        @app,
            event_name: log.event_name,
            event_id:   SecureRandom.uuid,
            payload:    log.payload,
            request_id: SecureRandom.hex(8)
          )
        else
          DeliverEventJob.perform_later(@app.id, log.event_name, log.payload)
        end
        redirect_to synchify.app_monitor_path(@app.app_code), notice: "Event retried"
      rescue => e
        redirect_to synchify.app_monitor_path(@app.app_code), alert: "Retry failed: #{e.message}"
      end

      private

      def set_app
        @app = App.find_by!(app_code: params[:app_code])
      end
    end
  end
end
