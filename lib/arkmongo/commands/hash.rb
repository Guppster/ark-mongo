# frozen_string_literal: true

require_relative '../cmd'
require 'pastel'
require 'mongo'
require 'digest'
require 'json'
require 'ark'

module Arkmongo
  module Commands
    # Handles hashing operations
    class Hash < Arkmongo::Cmd
      def initialize(mongo_uri, collection, options)
        @mongo_uri = mongo_uri
        @collection_name = collection
        @options = options
        @delegate_secret = 'planet wrap clever dirt silk dance prefer view try swap enact island'

        pastel = Pastel.new
        @output = pastel.blue.detach
        @error = pastel.red.detach
        @timestamp = pastel.yellow.detach

        # Connect to the mongo instance and get DB
        Mongo::Logger.logger.level = Logger::FATAL
        @client = Mongo::Client.new(@mongo_uri)

        @ark = Ark::Client.new(
          ip: '127.0.0.1',
          port: 14100,
          nethash: '6a0eab08d4b8c3c818f93bc45fb51f7317e50c4c764fbedbf9675bb0e688dc9a',
          version: '0.0.1',
          network_address: '1E'
        )
      end

      def display(output, level)
        puts @timestamp.call(Time.now.strftime("%H:%M:%S")) + ': ' + level.call(output)
      end

      def execute
        puts '------------------------------------------------------------------'
        puts
        display('Executing Hash command', @output)
        display('BIG ERROR OMG', @error)

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
        @hash_client = @client.use(:arkmongo)
        @hash_collection = @hash_client.database[:query_hashes]

        # Use an index view to setup indexes for the new collection
        hash_index_view = Mongo::Index::View.new(@hash_collection)

        # TODO: change to create_many method
        hash_index_view.create_one({ db: 1, collection: 1, query: 1,
                                     projection: 1 }, unique: true)

        hash_index_view.create_one({ hash: 1 }, unique: true)

        hash_index_view.create_one({ address: 1, blockStatus: 1,
                                     transactionID: 1, secret: 1 }, unique: true)
      end

      # Returns the hash of the database query specified on initialization
      def generate_hash
        # Setup hashing function
        sha256 = Digest::SHA256.new

        # Make sure we query the correct collection
        collection = @client[@collection_name]

        # Include the query in the hash
        sha256 << @options[:query].to_json

        # Include each document returned from query in the hash
        collection.find(@options[:query]).each do |document|
          sha256 << document.to_s
        end

        # Return the hash
        sha256.hexdigest
      end

      # Saves the hash
      def save_hash(hash)
        # Save the hash to the hash database
        save_hash_db(hash)

        # Save the hash to the blockchain
        save_hash_ark(hash)
      end

      def save_hash_db(hash)
        # Prepare hash structure
        hash_data = {
          hash: hash,
          blockStatus: 'pending creation',
          dateTime: Time.now
        }

        # Update the query with hash_data
        update_db(hash_data)
      end

      def update_db(update_hash,
                    database = @client.database.name,
                    collection = @collection_name,
                    query = @options[:query], projection = {})
        # Prepare filter query
        filter_data = {
          db: database,
          collection: collection,
          query: query,
          projection: projection
        }

        # Update the query with new hash data
        @hash_collection.update_one(filter_data, { '$set' => update_hash }, upsert: true)
      end

      def save_hash_ark(hash)
        process_transaction(hash)
      end

      def process_transaction(hash)
        # Get public key for the recipient address and push to the caching db
        public_key = retrieve_public_key.to_s
        secret = generate_secret

        update_db(address: public_key,
                  secret: secret,
                  blockStatus: 'signed and awaiting confirmation')

        # Create and send out a transaction
        @ark.create_transaction(public_key, 1, hash, @delegate_secret, nil)
      end

      # Return the public key corrisponding to this query's key
      def retrieve_public_key
        full_key = Ark::Util::Crypto.get_key(generate_secret)
        Ark::Util::Crypto.get_address(full_key, '1E')
      end

      # Generate the secret based on query details
      # This isn't bad because the value on the address is useless to us
      # We only care about transaction integrity which happens regardless of individual secrets
      def generate_secret
        Digest::SHA256.hexdigest "xx#{@client.database.name}xx#{@collection_name}xx#{@options[:query]}xx"
      end

      def verify; end
    end
  end
end
