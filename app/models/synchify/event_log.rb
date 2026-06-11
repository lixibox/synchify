module Synchify
  class EventLog < ApplicationRecord
    belongs_to :app

    synchify_enum :direction, {
      incoming: "incoming",
      outgoing: "outgoing"
    }

    validates :event_name, presence: true
    validates :direction, presence: true

    scope :for_event, ->(name) { where(event_name: name) }
    scope :recent, -> { order(created_at: :desc) }
  end
end
