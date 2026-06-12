module Synchify
  class ApiController < ActionController::API
    include ActionController::ParamsWrapper
    wrap_parameters false

    private

    def problem_details(type_slug, title, status, detail: nil)
      { type: "synchify.errors.#{type_slug}", title: title, status: status, detail: detail }.compact
    end
  end
end
