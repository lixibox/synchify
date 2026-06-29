module Synchify
  EventDefinition = Struct.new(:resolver) do
    def klass
      @klass ||= resolver.call
    end

    def description
      klass.respond_to?(:description) ? klass.description : nil
    end

    def params_schema
      if klass.respond_to?(:params_schema)
        klass.params_schema
      elsif klass.respond_to?(:schema)
        klass.schema
      end
    end

    def response_schema
      klass.respond_to?(:response_schema) ? klass.response_schema : nil
    end

    def payload_validations
      klass.respond_to?(:payload_validations) ? klass.payload_validations : []
    end
  end

  class Configuration
    attr_accessor :app_name, :app_code, :secret_key, :authenticate_with

    def initialize
      @handle_events  = {}
      @payload_events = {}
    end

    def handle_event(name, &block)
      @handle_events[name.to_s] = EventDefinition.new(block)
    end

    def payload_event(name, &block)
      @payload_events[name.to_s] = EventDefinition.new(block)
    end

    def handle_events
      @handle_events
    end

    def payload_events
      @payload_events
    end
  end
end
