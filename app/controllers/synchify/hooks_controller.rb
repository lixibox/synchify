module Synchify
  class HooksController < ApiController
    before_action :set_app
    before_action :verify_signature!
    before_action :check_duplicate!

    def receive
      result = WebhookProcessor.call(
        app:        @app,
        event_name: event_meta[:name],
        event_id:   event_meta[:id],
        payload:    params[:payload]&.to_unsafe_h,
        request_id: request.request_id
      )
      render json: result.body, status: result.status
    end

    private

    def set_app
      unless params[:app_code] == Synchify.configuration.app_code
        render json: problem_details("app-not-found", "App Not Found", 404), status: :not_found and return
      end
      sender_code = request.headers["X-Synchify-App-Code"].presence
      @app = sender_code && App.approved.find_by(app_code: sender_code)
      render json: problem_details("app-not-found", "App Not Found", 404), status: :not_found unless @app
    end

    def verify_signature!
      verifier = SignatureVerifier.new(
        secret:    @app.api_key,
        signature: request.headers["X-Synchify-Signature"].to_s,
        timestamp: request.headers["X-Synchify-Timestamp"].to_s,
        body:      request.raw_post
      )
      unless verifier.valid?
        render json: problem_details("invalid-signature", "Invalid Signature", 401, detail: "HMAC signature does not match payload."), status: :unauthorized
      end
    end

    def check_duplicate!
      event_id = request.headers["X-Synchify-Event-ID"].presence
      return unless event_id
      if EventLog.exists?(app: @app, event_id: event_id)
        render json: problem_details("duplicate-event", "Duplicate Event", 409), status: :conflict
      end
    end

    def event_meta
      params.require(:event).permit(:id, :name, :timestamp)
    end
  end
end
