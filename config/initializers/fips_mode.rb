# frozen_string_literal: true

if Rails.configuration.x.fips_mode
  module SciDigest
    module SHA2
      def new(bitlen = 256)
        @sha2 =
          case bitlen
          when 512
            OpenSSL::Digest.new('SHA512')
          when 384
            @sha2 = OpenSSL::Digest.new('SHA384')
          else
            @sha2 = OpenSSL::Digest.new('SHA256')
          end
        @bitlen = bitlen
        @sha2
      end
    end
  end

  # Replace built in digest implementations with OpenSSL, disable MD5
  Digest.__send__(:remove_const, :MD5)
  Digest::SHA2.singleton_class.prepend(SciDigest::SHA2)
  %i(SHA1 SHA256 SHA384 SHA512).each do |algo|
    Digest.__send__(:remove_const, algo)
    Digest.const_set(algo, OpenSSL::Digest.const_get(algo))
  end

  # OpenSSL library should be configured in FIPS mode
  Rails.application.config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA256
  Rails.application.config.active_support.hash_digest_class = OpenSSL::Digest::SHA256
end
