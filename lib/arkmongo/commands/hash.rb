# frozen_string_literal: true

require_relative '../cmd'
require 'mongo'

module Arkmongo
  module Commands
    class Hash < Arkmongo::Cmd
      def initialize(mongo_uri, collection, options)
        @mongo_uri = mongo_uri
        @collection = collection
        @options = options
      end

      def execute
        # Connect to the mongo instance and get DB
        client = Mongo::Client.new(@mongo_uri)
        db = client.database

        # Confirming the db connection [debug!]
        puts db.collections

        puts '---testing---'

        puts db.collection_names

        # Create a new DB for storing hashes (hashDB)
        init_hash_db

        # Generate hash using args DB, collection, and query options
        hash = generate_hash

        # Save the hash to hashDB and blockchain
        save_hash(hash)

        # Verify the hash was sucessfully saved
        verify
      end

      def init_hash_db; end

      def generate_hash
        'hash'
      end

      # Saves the hash
      def save_hash(hash)
        # Save the hash to the hash database
        save_hash_db(hash)

        # Save the hash to the blockchain
        save_hash_ark(hash)
      end

      def save_hash_db(hash); end

      def save_hash_ark(hash); end

      def verify; end
    end
  end
end
