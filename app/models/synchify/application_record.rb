module Synchify
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    def self.synchify_enum(name, values, **opts)
      if ActiveRecord::VERSION::MAJOR >= 7
        enum(name, values, **opts)
      else
        enum({ name => values }.merge(opts))
      end
    end
  end
end
