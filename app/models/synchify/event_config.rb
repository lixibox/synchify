module Synchify
  class EventConfig < ApplicationRecord
    belongs_to :app

    synchify_enum :direction, {
      incoming: "incoming",
      outgoing: "outgoing"
    }

    synchify_enum :state, {
      active:   "active",
      paused:   "paused",
      disabled: "disabled"
    }

    validates :event_name, presence: true, uniqueness: { scope: [ :app_id, :direction ] }

    def accepting?
      active?
    end

    def broadcasting?
      active?
    end
  end
end
