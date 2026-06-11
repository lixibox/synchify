module Synchify
  class UiController < ApplicationController
    before_action :synchify_authenticate!

    private

    def synchify_authenticate!
      guard = Synchify.configuration.authenticate_with
      return instance_exec(&guard) if guard

      render "synchify/errors/forbidden", status: :forbidden, layout: false
    end
  end
end
