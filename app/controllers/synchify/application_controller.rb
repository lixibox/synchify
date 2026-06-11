module Synchify
  class ApplicationController < ::ApplicationController
    layout "synchify/application"
    protect_from_forgery with: :exception
  end
end
