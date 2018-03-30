# frozen_string_literal: true

require_relative '../cmd'
require 'mongo'
require 'digest'

module Arkmongo
  module Commands
    # Handles hashing operations
    class Hash < Arkmongo::Cmd
      def initialize(mongo_uri, collection, options)
        @mongo_uri = mongo_uri
        @collection_name = collection
        @options = options

        # Connect to the mongo instance and get DB
        @client = Mongo::Client.new(@mongo_uri)
      end

      def execute
        # Create a new DB for storing hashes (hashDB)
        init_hash_db

        # Generate hash using args DB, collection, and query options
        hash = generate_hash

        # Save the hash to hashDB and blockchain
        save_hash(hash)

        # Verify the hash was sucessfully saved
        verify
      end

      # Creates a database to store previous queries and their hashes for
      # validation in the future
      def init_hash_db
        # Get a new client that handles the 'arkmongo' database
        hash_client = @client.use(:arkmongo)
        hash_collection = hash_client.database[:query_hashes]

        # Use an index view to setup indexes for the new collection
        hash_index_view = Mongo::Index::View.new(hash_collection)

        # TODO: change to create_many method
        hash_index_view.create_one({ db: 1, collection: 1, query: 1,
                                     projection: 1 }, unique: true)

        hash_index_view.create_one({ hash: 1 }, unique: true)
      end

      def generate_hash
        # Setup hashing function
        sha256 = Digest::SHA256.new

        # Make sure we query the correct collection
        collection = @client[:@collection_name]

        # Include the query in the hash
        sha256 << @options[:query]

        # Include each document returned from query in the hash
        collection.find(@options[:query]).each do |document|
          sha256 << document
        end

        # Return the hash
        sha256.digest
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
