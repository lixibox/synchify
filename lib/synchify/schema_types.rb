module Synchify
  module SchemaTypes
    JSON_TYPES = {
      Integer  => "integer", :integer => "integer",
      Float    => "number",  :number  => "number",
      :boolean => "boolean",
      Array    => "array",   :array   => "array",
      Hash     => "object",  :object  => "object",
      String   => "string",  :string  => "string"
    }.freeze

    private

    def build_property(type, desc)
      prop = { "type" => JSON_TYPES.fetch(type, "string") }
      prop["description"] = desc if desc
      prop
    end
  end
end
