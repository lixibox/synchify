module Synchify
  class HandleEvent < Event
    def self.payload_validate(field, **rules)
      @_payload_validations ||= []
      @_payload_validations << { field: field.to_s, **rules }
    end

    def self.payload_validations
      @_payload_validations || []
    end

    def load(payload)
      @payload = payload.transform_keys(&:to_s)
    end

    def payload_valid?
      payload_errors.empty?
    end

    def handle
      raise NotImplementedError, "#{self.class}#handle not implemented"
    end

    def self.handle(payload)
      handler = self.new
      handler.load(payload)
      handler.payload_valid? || raise(BadPayloadError, payload_errors)
      handler.handle
      handler
    end

    private

    attr_reader :payload
    attr_reader :errors

    def payload_errors
      @errors = []
      self.class.payload_validations.each do |rule|
        value = @payload[rule[:field]]
        next if value.nil?

        if rule.key?(:in)
          allowed = rule[:in]
          allowed = allowed.call if allowed.respond_to?(:call)
          @errors << "#{rule[:field]} is not included in the list" unless allowed.include?(value)
        end
      end
      @errors
    end
  end
end
