module Synchify
  class Error < StandardError
    def messsage
      "Synchify: #{super}"
    end
  end
end

class Synchify::BadPayloadError < Synchify::Error
  def messsage
    "Synchify: Invalid payload #{super}"
  end
end
