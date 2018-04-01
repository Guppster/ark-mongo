require 'btcruby'

module Ark
  module Util

    # Handles some crypto functionality not included in the ark-ruby dependency
    module Crypto
      def self.get_key(secret)
        BTC::Key.new(private_key: Digest::SHA256.digest(secret),
                     public_key_compressed: true)
      end

      def self.verify(transaction)
        public_only_key = BTC::Key.new(public_key: [transaction.sender_public_key].pack('H*'))

        public_only_key.verify_ecdsa_signature([transaction.signature].pack('H*'),
                                               Digest::SHA256.digest(transaction.to_bytes))
      end

      def self.second_verify(transaction, second_public_key_hex)
        public_only_key = BTC::Key.new(public_key: [second_public_key_hex].pack('H*'))

        public_only_key.verify_ecdsa_signature(
          [transaction.sign_signature].pack('H*'),Digest::SHA256.digest(transaction.to_bytes(false)))
      end

      def self.get_address(key, network_address = '1e')
        BTC::Base58.base58check_from_data(
          [network_address.to_i(16)].pack('c') + Digest::RMD160.digest(key.public_key))
      end
    end
  end
end

