# frozen_string_literal: true

require_relative '../cmd'
require 'tty-progressbar'
require 'pastel'
require 'mongo'
require 'digest'
require 'json'
require 'ark'
require 'neatjson'

module Arkmongo
  module Commands
    # Handles hashing operations
    class Hash < Arkmongo::Cmd
      def initialize(mongo_uri, secret, nethash, collection, options)
        @mongo_uri = mongo_uri
        @collection_name = collection
        @options = options
        @delegate_secret = secret
        @nethash = nethash

        pastel = Pastel.new
        @output = pastel.blue.detach
        @db_output = pastel.cyan.detach
        @blockchain_output = pastel.green.detach
        @error = pastel.red.detach
        @timestamp = pastel.yellow.detach
      end

      def setup
        puts '------------------------------------------------------------------'
        puts
        display('Executing Hash command', @output)

        # Connect to the mongo instance and get DB
        Mongo::Logger.logger.level = Logger::FATAL
        @client = Mongo::Client.new(@mongo_uri)

        @ark = Ark::Client.new(
          ip: '127.0.0.1',
          port: 14100,
          nethash: @nethash,
          version: '0.0.1',
          network_address: '1E'
        )
      end

      def execute
        # Setup ARK and HashDB
        setup

        # Create a new DB for storing hashes (hashDB)
        init_hash_db

        # Generate hash using args DB, collection, and query options
        hash = generate_hash

        # Save the hash to hashDB
        save_hash_db(hash)

        # Send hash to blockchain
        result = send_to_blockchain(hash)

        # Verify the hash was sucessfully saved
        verify(result)
      end

      # Creates a database to store previous queries and their hashes for
      # validation in the future
      def init_hash_db

        display('Initializing HashDB', @output)
        # Get a new client that handles the 'arkmongo' database
        @hash_client = @client.use(:arkmongo)
        @hash_collection = @hash_client.database[:query_hashes]

        # Use an index view to setup indexes for the new collection
        hash_index_view = Mongo::Index::View.new(@hash_collection)

        display('Creating query_hashes collection indexes', @db_output)

        # TODO: change to create_many method
        hash_index_view.create_one({ db: 1, collection: 1, query: 1,
                                     projection: 1 }, unique: true)

        hash_index_view.create_one({ hash: 1 }, unique: true)

        hash_index_view.create_one({ address: 1, blockStatus: 1,
                                     result: 1, secret: 1 }, unique: true)
      end

      # Returns the hash of the database query specified on initialization
      def generate_hash
        display('Generating document hash', @output)
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

        display("Query hash is #{sha256.hexdigest}", @output)

        # Return the hash
        sha256.hexdigest
      end

      def save_hash_db(hash)
        display('Saving document hash', @output)
        # Prepare hash structure
        hash_data = {
          hash: hash,
          blockStatus: 'pending creation',
          dateTime: Time.now
        }

        # Update the query with hash_data
        update_db(hash_data)
        display('Successfully saved to caching DB', @db_output)
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

        display("updating cache db with \n" + JSON.neat_generate(update_hash) + "\nfor query\n" + JSON.neat_generate(filter_data), @db_output)

        # Update the query with new hash data
        @hash_collection.update_one(filter_data, { '$set' => update_hash }, upsert: true)
      end

      def send_to_blockchain(hash)
        result = process_transaction(hash)

        if result['success']
          display('Successfully sent to blockchain', @output)
        elsif display('Sending transaction to blockchain failed' + JSON.neat_generate(result), @error)
        end

        result
      end

      def process_transaction(hash)
        # Get public key for the recipient address and push to the caching db
        public_key = retrieve_public_key.to_s
        secret = generate_secret

        display("Query address is #{public_key}", @blockchain_output)

        display('Creating ark transaction', @blockchain_output)
        # Create and send out a transaction and returns transactionIds
        result = @ark.create_transaction(public_key, 1, hash, @delegate_secret, nil)

        display('Saving blockchain details to cache', @output)
        update_db(address: public_key,
                  secret: secret,
                  result: result,
                  blockStatus: 'signed and awaiting confirmation')

        result
      end

      # Return the public key corrisponding to this query's key
      def retrieve_public_key
        display('Generating public key', @blockchain_output)

        secret = generate_secret
        display("Query secret is #{secret}", @blockchain_output)

        full_key = Ark::Util::Crypto.get_key(secret)

        display('Prefix 1E (30)/(D) is being used which is already associated with dArk', @error)
        Ark::Util::Crypto.get_address(full_key, '1E')
      end

      # Generate the secret based on query details
      # This isn't bad because the value on the address is useless to us
      # We only care about transaction integrity which happens regardless of individual secrets
      def generate_secret
        display('Generating secret', @blockchain_output)
        Digest::SHA256.hexdigest "xx#{@client.database.name}xx#{@collection_name}xx#{@options[:query]}xx"
      end

      def verify(result)
        transaction_id = result['transactionIds'][0]
        display("Verifying transaction #{transaction_id}", @blockchain_output)
      end

      def display(output, level)
        if level == @blockchain_output
          label = '[ARK]: '
        elsif level == @db_output
          label = '[DB]: '
        elsif level == @output
          label = '[ArkMongo]: '
        elsif level == @error
          label = '[WARNING]: '
        end

        puts @timestamp.call(Time.now.strftime("%H:%M:%S")) + ': ' + level.call(label + output)
      end
    end
  end
end
