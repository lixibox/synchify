require "openssl"

module Synchify
  class SignatureVerifier
    TOLERANCE = 300 # 5 min skew

    def initialize(secret:, signature:, timestamp:, body:)
      @secret    = secret.to_s
      @signature = signature.to_s
      @timestamp = timestamp.to_i
      @body      = body.to_s
    end

    def valid?
      return false if @signature.empty?
      return false if timestamp_expired?

      ActiveSupport::SecurityUtils.secure_compare(@signature, expected_signature)
    end

    private

    def timestamp_expired?
      (Time.current.to_i - @timestamp).abs > TOLERANCE
    end

    def expected_signature
      OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{@timestamp}\n#{@body}")
    end
  end
end
