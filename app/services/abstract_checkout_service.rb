# frozen_string_literal: true

class AbstractCheckoutService < BaseService
  class InvalidAlgorithmError < StandardError; end
  class InvalidIncludeError < StandardError; end
  class InvalidTTLError < StandardError; end

  ENCRYPT_ALGORITHM = 'aes-128-gcm'
  ENCODE_ALGORITHM  = 'base64'

  def initialize(account:, algorithm:, encrypt: true, ttl: 1.month, includes: [])
    raise InvalidTTLError.new('must be greater than or equal to 3600 (1 hour)') if
      ttl.present? && ttl < 1.hour

    @renderer  = Keygen::JSONAPI::Renderer.new(context: :checkout)
    @account   = account
    @algorithm = algorithm
    @encrypted = encrypt
    @ttl       = ttl
    @includes  = includes
  end

  def call
    raise NotImplementedError, '#call must be implemented by a subclass'
  end

  private

  attr_reader :renderer,
              :account,
              :algorithm,
              :encrypted,
              :ttl,
              :includes

  def encrypted?
    !!encrypted
  end

  def encoded?
    !encrypted?
  end

  def ttl?
    ttl.present?
  end

  def encrypt(value, secret:)
    cipher = OpenSSL::Cipher::Cipher.new(ENCRYPT_ALGORITHM)
    cipher.encrypt

    key = OpenSSL::Digest::MD5.digest(secret)
    iv  = cipher.random_iv

    cipher.key = key
    cipher.iv  = iv

    ciphertext = cipher.update(value) + cipher.final

    [ciphertext, iv].map { encode(_1, strict: true) }
                    .join('.')
                    .chomp
  end

  def encode(value, strict: false)
    enc = if strict
            Base64.strict_encode64(value)
          else
            Base64.encode64(value)
          end

    enc.chomp
  end

  def sign(value, prefix:)
    data = "#{prefix}/#{value}"

    case algorithm
    when 'rsa-pss-sha256'
      pkey = OpenSSL::PKey::RSA.new(account.private_key)
      sig  = pkey.sign_pss(OpenSSL::Digest::SHA256.new, data, salt_length: :max, mgf1_hash: 'SHA256')
    when 'rsa-sha256'
      pkey = OpenSSL::PKey::RSA.new(account.private_key)
      sig = pkey.sign(OpenSSL::Digest::SHA256.new, data)
    when 'ed25519'
      pkey = Ed25519::SigningKey.new([account.ed25519_private_key].pack('H*'))
      sig  = pkey.sign(data)
    else
      raise InvalidAlgorithmError, 'signing algorithm is invalid'
    end

    encode(sig, strict: true)
  end
end