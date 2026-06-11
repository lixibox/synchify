require "openssl"

module Synchify
  class HandshakeService
    def self.approve(connection_request, hook_url:, app_url:)
      new(connection_request, hook_url: hook_url, app_url: app_url).approve
    end

    def self.reject(connection_request, app_url:)
      new(connection_request, app_url: app_url).reject
    end

    def initialize(connection_request, hook_url: nil, app_url: nil)
      @cr       = connection_request
      @hook_url = hook_url
      @app_url  = app_url
    end

    def approve
      api_key_for_requester = SecureRandom.hex(32)

      app = App.find_or_initialize_by(app_code: requester["app_code"])
      app.update!(
        name:             requester["app_name"],
        api_key:          requester["api_key"],   # B's key → A uses to verify B's incoming requests
        secret_token:     api_key_for_requester,  # A's key → sent to B, A uses for outgoing requests to B
        app_url:          requester["app_url"].presence,
        hook_url:         requester["hook_url"].presence,
        status:           :approved,
        connection_state: :active
      )

      @cr.approved!

      send_callback("approved", api_key_for_requester) if requester["app_url"].present?
      app
    end

    def reject
      @cr.rejected!
      send_callback("rejected", nil) if requester["app_url"].present?
    end

    private

    def requester
      @cr.requester_info
    end

    def send_callback(status, api_key)
      config  = Synchify.configuration
      payload = {
        status:     status,
        app_name:   config.app_name,
        app_code:   config.app_code,
        api_key:    api_key,
        hook_url:   @hook_url,
        app_url:    @app_url,
        verify_key: sign_verify_key
      }

      NetRequest.post(requester["app_url"], body: payload)
    rescue => e
      Rails.logger.error "[Synchify] Callback failed to #{requester['app_url']}: #{e.message}"
    end

    def sign_verify_key
      OpenSSL::HMAC.hexdigest("SHA256", Synchify.configuration.secret_key.to_s, @cr.request_key.to_s)
    end
  end
end
