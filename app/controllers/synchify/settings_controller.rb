module Synchify
  class SettingsController < UiController
    def show
      @config        = Synchify.configuration
      @request_key   = RequestKeyManager.current
      @handshake_url = connect_url
    end

    def reset
      head :forbidden and return unless Rails.env.development?

      [ EventLog, EventConfig, App, ConnectionRequest ].each(&:delete_all)
      redirect_to settings_path, notice: "Synchify database reset."
    end
  end
end
