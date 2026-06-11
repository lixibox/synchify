module Synchify
  class HandleEvent < Event
    def handle(payload)
      raise NotImplementedError, "#{self.class}#handle not implemented"
    end
  end
end
