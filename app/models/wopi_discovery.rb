# frozen_string_literal: true

class WopiDiscovery < ApplicationRecord
  require 'base64'

  has_many :wopi_apps,
           class_name: 'WopiApp',
           foreign_key: 'wopi_discovery_id',
           dependent: :destroy
  validates :expires,
            :proof_key_mod,
            :proof_key_exp,
            :proof_key_old_mod,
            :proof_key_old_exp,
            presence: true

  # Verifies if proof from headers, X-WOPI-Proof/X-WOPI-OldProof was encrypted
  # with this discovery public key (two key possible old/new)
  def verify_proof(token, timestamp, signed_proof, signed_proof_old, url)
    token_length = [token.length].pack('>N').bytes
    timestamp_bytes = [timestamp.to_i].pack('>Q').bytes.reverse
    timestamp_length = [timestamp_bytes.length].pack('>N').bytes
    url_length = [url.length].pack('>N').bytes

    expected_proof = token_length + token.bytes +
                     url_length + url.upcase.bytes +
                     timestamp_length + timestamp_bytes

    key = generate_key(proof_key_mod, proof_key_exp)
    old_key = generate_key(proof_key_old_mod, proof_key_old_exp)

    # Try all possible combiniations
    try_verification(expected_proof, signed_proof, key) ||
      try_verification(expected_proof, signed_proof_old, key) ||
      try_verification(expected_proof, signed_proof, old_key)
  end

  # Generates a public key from given modulus and exponent
  def generate_key(modulus, exponent)
    mod = Base64.decode64(modulus).unpack('H*').first.to_i(16)
    exp = Base64.decode64(exponent).unpack('H*').first.to_i(16)

    seq = OpenSSL::ASN1::Sequence.new([OpenSSL::ASN1::Integer.new(mod),
                                       OpenSSL::ASN1::Integer.new(exp)])
    OpenSSL::PKey::RSA.new(seq.to_der)
  end

  # Verify if decrypting signed_proof with public_key equals to expected_proof
  def try_verification(expected_proof, signed_proof_b64, public_key)
    signed_proof = Base64.decode64(signed_proof_b64)
    public_key.verify(OpenSSL::Digest::SHA256.new, signed_proof,
                      expected_proof.pack('c*'))
  end

end
