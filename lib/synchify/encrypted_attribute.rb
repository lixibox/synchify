module Synchify
  module EncryptedAttribute
    extend ActiveSupport::Concern

    ENCRYPTED_FIELDS = %i[api_key secret_token].freeze

    included do
      ENCRYPTED_FIELDS.each do |field|
        define_method(field) do
          raw = read_attribute(field)
          return nil if raw.blank?
          field_encryptor.decrypt_and_verify(raw)
        rescue ActiveSupport::MessageEncryptor::InvalidMessage,
               ActiveSupport::MessageVerifier::InvalidSignature
          nil
        end

        define_method(:"#{field}=") do |value|
          write_attribute(field, value.present? ? field_encryptor.encrypt_and_sign(value) : nil)
        end
      end
    end

    private

    def field_encryptor
      key = ActiveSupport::KeyGenerator.new(
        Synchify.configuration.secret_key
      ).generate_key("synchify_field_encryption", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
