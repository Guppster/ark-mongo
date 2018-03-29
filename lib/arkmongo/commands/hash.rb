# frozen_string_literal: true

require_relative '../cmd'

module Arkmongo
  module Commands
    class Hash < Arkmongo::Cmd
      def initialize(mongo_uri, options)
        @mongo_uri = mongo_uri
        @options = options
      end

      def execute
        # Command logic goes here ...
      end
    end
  end
end
