module Synchify
  class ConnectController < ApiController
    def receive
      if callback?
        handle_callback
      else
        handle_connection_request
      end
    end

    private

    def callback?
      params[:status].present? && params[:verify_key].present?
    end

    def handle_connection_request
      unless RequestKeyManager.valid?(params[:request_key])
        render json: problem_details("invalid-request-key", "Invalid Request Key", 401), status: :unauthorized and return
      end

      RequestKeyManager.rotate!

      ConnectionRequest.create!(
        requester_info: connection_request_params,
        request_key:    params[:request_key],
        status:         :pending,
        expires_at:     7.days.from_now
      )

      config = Synchify.configuration
      render json: {
        received: true,
        app_name: config.app_name,
        app_code: config.app_code
      }, status: :ok
    end

    def handle_callback
      connection_request = find_connection_request_from_verify_key
      unless connection_request
        render json: problem_details("invalid-verify-key", "Invalid Verify Key", 401), status: :unauthorized and return
      end

      if params[:status] == "approved"
        connection_request.approved!
        App.find_or_initialize_by(app_code: params[:app_code]).update!(
          name:             params[:app_name],
          api_key:          params[:api_key],
          app_url:          params[:app_url],
          hook_url:         params[:hook_url],
          secret_token:     connection_request.requester_info["api_key"],
          status:           :approved,
          connection_state: :active
        )
      else
        connection_request.rejected!
      end

      render json: { acknowledged: true }, status: :ok
    end

    def find_connection_request_from_verify_key
      secret = Synchify.configuration.secret_key.to_s
      ConnectionRequest.active.find do |cr|
        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, cr.request_key.to_s)
        ActiveSupport::SecurityUtils.secure_compare(expected, params[:verify_key].to_s)
      end
    end

    def connection_request_params
      params.permit(:app_name, :app_code, :app_url, :hook_url, :api_key, :request_key).to_h
    end
  end
end
