module Synchify
  class PayloadEvent < Event
    def build(object)
      raise NotImplementedError, "#{self.class}#build not implemented"
    end

    def self.build(object)
      self.new.build(object)
    end
  end
end
