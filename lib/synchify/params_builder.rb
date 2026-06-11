module Synchify
  class ParamsBuilder
    include SchemaTypes

    def initialize
      @properties = {}
      @required   = []
    end

    def requires(name, type: String, desc: nil)
      @required << name.to_s
      @properties[name.to_s] = build_property(type, desc)
    end

    def optional(name, type: String, desc: nil)
      @properties[name.to_s] = build_property(type, desc)
    end

    def to_schema
      schema = { "type" => "object", "properties" => @properties }
      schema["required"] = @required unless @required.empty?
      schema
    end
  end
end
