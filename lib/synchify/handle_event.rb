module Synchify
  class HandleEvent < Event
    def handle(payload)
      raise NotImplementedError, "#{self.class}#handle not implemented"
    end

    def self.handle(payload)
      self.new.handle(payload)
    end
  end
end
