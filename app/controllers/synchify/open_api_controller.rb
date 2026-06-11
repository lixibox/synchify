module Synchify
  class OpenApiController < ApiController
    def show
      render json: OpenApiBuilder.spec
    end
  end
end
