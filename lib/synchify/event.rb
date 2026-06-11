require "yaml"

module Synchify
  class Event
    class << self
      def description(text = nil)
        text ? @description = text : @description
      end

      def params(klass_or_file = nil, &block)
        @params_schema = resolve_schema(ParamsBuilder, klass_or_file, &block)
      end

      def response(klass_or_file = nil, &block)
        @response_schema = resolve_schema(ResponseBuilder, klass_or_file, &block)
      end

      def params_schema
        @params_schema
      end

      def response_schema
        @response_schema
      end

      private

      def resolve_schema(builder_class, klass_or_file, &block)
        if block
          builder = builder_class.new
          builder.instance_eval(&block)
          builder.to_schema
        elsif klass_or_file.is_a?(String)
          YAML.load_file(Rails.root.join(klass_or_file))
        elsif klass_or_file.respond_to?(:schema)
          klass_or_file.schema
        end
      end
    end
  end
end
