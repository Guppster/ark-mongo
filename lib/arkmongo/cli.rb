# frozen_string_literal: true

require 'thor'

module Arkmongo
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'arkmongo version'
    def version
      require_relative 'version'
      puts "v#{Arkmongo::VERSION}"
    end
    map %w[(--version -v)] => :version

    desc 'hash <MONGO_URI> <COLLECTION_NAME>',
         'Generates a hash of the selected documents'

    method_option :query, type: :string, banner: 'mongo query', aliases: ['-q'],
                          desc: 'Narrows down the selected collection'

    def hash(mongo_uri, collection)
      if options[:help]
        invoke :help, ['hash']
      else
        require_relative 'commands/hash'
        Arkmongo::Commands::Hash.new(mongo_uri, collection, options).execute
      end
    end
  end
end
