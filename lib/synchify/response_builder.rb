module Synchify
  class ResponseBuilder
    include SchemaTypes

    def initialize
      @properties = {}
    end

    def property(name, type: String, desc: nil)
      @properties[name.to_s] = build_property(type, desc)
    end

    def to_schema
      { "type" => "object", "properties" => @properties }
    end
  end
end
