module Synchify
  class PayloadEvent < Event
    def build(object)
      raise NotImplementedError, "#{self.class}#build not implemented"
    end
  end
end
