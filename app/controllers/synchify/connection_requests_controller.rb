module Synchify
  class ConnectionRequestsController < UiController
    REQUEST_TTL = 7.days

    before_action :set_connection_request, only: [ :approve, :reject ]

    def new
      @config      = Synchify.configuration
      @connect_url = connect_url
    end

    def create
      remote_url, remote_request_key = parse_connect_info
      config            = Synchify.configuration
      generated_api_key = SecureRandom.hex(32)

      payload = {
        request_key: remote_request_key,
        api_key:     generated_api_key,
        app_name:    config.app_name,
        app_code:    config.app_code,
        app_url:     connect_url,
        hook_url:    app_hooks_url(config.app_code)
      }

      result = NetRequest.post(remote_url, body: payload)

      if result.success?
        handle_success(result.body, remote_url, remote_request_key, generated_api_key)
      else
        render_error("Remote returned #{result.code}: #{result.body.truncate(200)}")
      end
    rescue => e
      render_error(e.message)
    end

    def approve
      config = Synchify.configuration
      app = HandshakeService.approve(@cr,
        hook_url: app_hooks_url(config.app_code),
        app_url:  connect_url
      )
      redirect_to synchify.app_path(app.app_code), notice: "Approved."
    end

    def reject
      HandshakeService.reject(@cr, app_url: connect_url)
      redirect_to synchify.apps_path, notice: "Request rejected."
    end

    private

    def set_connection_request
      @cr = ConnectionRequest.active.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to synchify.apps_path, alert: "Request not found or already processed."
    end

    def handle_success(response_body, remote_url, remote_request_key, generated_api_key)
      body            = JSON.parse(response_body) rescue {}
      remote_app_code = body["app_code"].presence
      remote_app_name = body["app_name"].presence

      ConnectionRequest.create!(
        requester_info: {
          app_url:  remote_url,
          app_code: remote_app_code,
          app_name: remote_app_name,
          api_key:  generated_api_key  # used as secret_token when App is created on callback
        },
        request_key: remote_request_key,
        status:      :pending,
        expires_at:  REQUEST_TTL.from_now
      )

      redirect_to synchify.root_path, notice: "Connection request sent to #{remote_app_name || remote_url}."
    end

    def render_error(message)
      @config      = Synchify.configuration
      @connect_url = connect_url
      @error       = message
      render :new, status: :unprocessable_entity
    end

    def parse_connect_info
      uri          = URI.parse(params[:connect_info].to_s.strip)
      query_params = URI.decode_www_form(uri.query.to_s).to_h
      uri.query    = nil
      [ uri.to_s, query_params["key"].to_s ]
    end
  end
end
