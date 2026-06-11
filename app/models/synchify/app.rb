module Synchify
  class App < ApplicationRecord
    include EncryptedAttribute

    synchify_enum :status, {
      requested: "requested",
      approved: "approved",
      rejected: "rejected"
    }

    synchify_enum :connection_state, {
      active: "active",
      paused: "paused",
      disabled: "disabled"
    }

    has_many :event_configs, dependent: :destroy
    has_many :event_logs, dependent: :destroy

    validates :name, presence: true
    validates :app_code, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }

    after_update :sync_event_configs, if: -> { saved_change_to_status? && approved? }

    private

    def sync_event_configs
      EventConfigSyncer.sync(self)
    end
  end
end
