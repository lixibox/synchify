module Synchify
  class PayloadValidator
    def initialize(event_name:, payload:)
      @event_name = event_name
      @payload    = payload.transform_keys(&:to_s)
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= validate
    end

    private

    def validate
      schema = event_klass&.params_schema
      return [] unless schema

      errs = []

      (schema["required"] || []).each do |field|
        errs << "#{field} is required" unless @payload.key?(field)
      end

      (schema["properties"] || {}).each do |field, prop|
        value = @payload[field]
        next if value.nil?
        errs << "#{field} must be #{prop['type']}" unless valid_type?(value, prop["type"])
      end

      errs
    end

    def event_klass
      Synchify.configuration.handle_events[@event_name]
    end

    def valid_type?(value, type)
      case type
      when "integer" then value.is_a?(Integer)
      when "number"  then value.is_a?(Numeric)
      when "boolean" then value.is_a?(TrueClass) || value.is_a?(FalseClass)
      when "array"   then value.is_a?(Array)
      when "object"  then value.is_a?(Hash)
      else true
      end
    end
  end
end
