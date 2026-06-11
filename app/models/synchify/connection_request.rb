module Synchify
  class ConnectionRequest < ApplicationRecord
    synchify_enum :status, {
      pending: "pending",
      approved: "approved",
      rejected: "rejected"
    }

    validates :request_key, presence: true, uniqueness: true
    validates :requester_info, presence: true
    validates :expires_at, presence: true

    scope :active, -> { pending.where("expires_at > ?", Time.current) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }

    def expired?
      expires_at <= Time.current
    end
  end
end
