module Synchify
  module ApplicationHelper
    def status_code_class(code)
      case code.to_i
      when 200..299 then "status-code--success"
      when 400..499 then "status-code--client-error"
      when 500..599 then "status-code--server-error"
      else               "status-code--unknown"
      end
    end
  end
end
