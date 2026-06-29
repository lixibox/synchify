require "synchify/version"
require "synchify/error"
require "synchify/schema_types"
require "synchify/params_builder"
require "synchify/response_builder"
require "synchify/event"
require "synchify/handle_event"
require "synchify/payload_event"
require "synchify/configuration"
require "synchify/encrypted_attribute"
require "synchify/signature_verifier"
require "synchify/payload_validator"
require "synchify/webhook_processor"
require "synchify/event_config_syncer"
require "synchify/open_api_builder"
require "synchify/request_key_manager"
require "synchify/net_request"
require "synchify/handshake_service"
require "synchify/trigger_event"
require "haml-rails"
require "synchify/engine"

module Synchify
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
      OpenApiBuilder.reset!
    end
  end
end
