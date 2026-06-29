Synchify::Engine.routes.draw do
  # Public
  get  "health",               to: "health#show"
  get  "openapi.json",         to: "open_api#show"

  # API
  post "connect",              to: "connect#receive"
  post "apps/:app_code/hooks", to: "hooks#receive", as: :app_hooks

  # UI Dashboard
  root to: "apps#index"
  get    "settings",       to: "settings#show",  as: :settings
  get    "events",         to: "events#index",   as: :events
  delete "settings/reset", to: "settings#reset", as: :reset_settings
  get  "connection_requests/new",  to: "connection_requests#new",    as: :new_connection_request
  post "connection_requests",      to: "connection_requests#create", as: :connection_requests
  post "connection_requests/:id/approve", to: "connection_requests#approve", as: :approve_connection_request
  post "connection_requests/:id/reject",  to: "connection_requests#reject",  as: :reject_connection_request

  resources :apps, only: [ :index, :show ], param: :app_code do
    member do
      patch :toggle_connection_state
    end
  end

  scope "/apps/:app_code", module: :apps, as: :app do
    get   "setting",             to: "settings#show",         as: :setting
    patch "setting",             to: "settings#update"
    get   "events",              to: "events#show",           as: :events
    get   "monitor",             to: "monitor#show",          as: :monitor
    post  "monitor/retry/:log_id", to: "monitor#retry_log",  as: :retry_event_log
    patch "event_configs/toggle", to: "events#toggle_event",  as: :toggle_event
    patch "event_configs/:id",   to: "events#update_event",   as: :update_event
    patch "event_configs/:id/incoming", to: "settings#update_event", as: :update_handle_event
    patch "event_configs/:id/outgoing", to: "events#update_event",  as: :update_payload_event
  end
end
