# frozen_string_literal: true

require 'test_helper'

# Since the encrypted values use openssl and are non-deterministic, we can never know the
# actual value to test against. All we can do is ensure the value is in the correct format
# for the encrypted content, which verifies it's not in the original state
ENCRYPTED_VALUE_PATTERN = %('?([a-z0-9A-Z=/+]+)\-\-([a-z0-9A-Z=/+]+)\-\-([a-z0-9A-Z=/+]+)'?)

class Diffcrypt::EncryptorTest < Minitest::Test
  def test_it_decrypts_root_values
    encrypted_content = <<~CONTENT
      secret_key_base: 88Ry6HESUoXBr6QUFXmni9zzfCIYt9qGNFvIWFcN--4xoecI5mqbNRBibI--62qPJbkzzh5h8lhFEFOSaQ==
    CONTENT
    expected = <<~CONTENT
      ---
      secret_key_base: secret_key_base_test
    CONTENT

    assert_equal Diffcrypt::Encryptor.new(TEST_KEY).decrypt(encrypted_content), expected
  end

  def test_it_encrypts_root_values
    content = <<~CONTENT
      ---
      secret_key_base: secret_key_base_test
    CONTENT
    expected_pattern = /---\nsecret_key_base: #{ENCRYPTED_VALUE_PATTERN}\n/

    assert_match expected_pattern, Diffcrypt::Encryptor.new(TEST_KEY).encrypt(content)
  end

  def test_it_decrypts_nested_structures
    encrypted_content = <<~CONTENT
      secret_key_base: 88Ry6HESUoXBr6QUFXmni9zzfCIYt9qGNFvIWFcN--4xoecI5mqbNRBibI--62qPJbkzzh5h8lhFEFOSaQ==
      aws:
        access_key_id: Ot/uCTEL+8kp61EPctnxNlg=--Be6sg7OdvjZlfxgR--7qRbbf0lA4VgjnUGUrrFwg==
    CONTENT
    expected = <<~CONTENT
      ---
      secret_key_base: secret_key_base_test
      aws:
        access_key_id: AKIAXXX
    CONTENT

    assert_equal Diffcrypt::Encryptor.new(TEST_KEY).decrypt(encrypted_content), expected
  end

  def test_it_encrypts_nested_structures
    content = <<~CONTENT
      ---
      secret_key_base: secret_key_base_test
      aws:
        access_key_id: AKIAXXX
    CONTENT
    expected_pattern = /---\nsecret_key_base: #{ENCRYPTED_VALUE_PATTERN}\naws:\n  access_key_id: #{ENCRYPTED_VALUE_PATTERN}\n/

    assert_match expected_pattern, Diffcrypt::Encryptor.new(TEST_KEY).encrypt(content)
  end

  # Verifies that a change to one key does not cause the encrypted values for other keys to be recomputed
  # Mainly used in conjunction with rails credentials editor
  def test_it_only_updates_changed_values
    original_encrypted_content = "---\nsecret_key_base_1: 88Ry6HESUoXBr6QUFXmni9zzfCIYt9qGNFvIWFcN--4xoecI5mqbNRBibI--62qPJbkzzh5h8lhFEFOSaQ==\naws:\n  secret_access_key: 88Ry6HESUoXBr6QUFXmni9zzfCIYt9qGNFvIWFcN--4xoecI5mqbNRBibI--62qPJbkzzh5h8lhFEFOSaQ==\n"
    updated_content = "---\nsecret_key_base_1: secret_key_base_test\naws:\n  secret_access_key: secret_access_key_2"
    expected_pattern = /---\nsecret_key_base_1: 88Ry6HESUoXBr6QUFXmni9zzfCIYt9qGNFvIWFcN--4xoecI5mqbNRBibI--62qPJbkzzh5h8lhFEFOSaQ==\naws:\n  secret_access_key: #{ENCRYPTED_VALUE_PATTERN}\n/

    assert_match expected_pattern, Diffcrypt::Encryptor.new(TEST_KEY).encrypt(updated_content, original_encrypted_content)
  end
end