class Testing
  extend AttrEncrypted

  attr_encrypted :api_key, :api_secret,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_truncated,
    algorithm: 'aes-256-gcm'
end
