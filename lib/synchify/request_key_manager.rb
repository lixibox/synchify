module Synchify
  class RequestKeyManager
    CACHE_KEY = "synchify:active_request_key"
    TTL = 1.day

    def self.current
      Rails.cache.fetch(CACHE_KEY, expires_in: TTL) { SecureRandom.hex(32) }
    end

    def self.rotate!
      Rails.cache.delete(CACHE_KEY)
      current
    end

    def self.valid?(key)
      return false if key.blank?
      ActiveSupport::SecurityUtils.secure_compare(current, key.to_s)
    end
  end
end
