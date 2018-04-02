# ark-mongo

[![demo](https://asciinema.org/a/Do1FXheRIw5TN05e8FRFmLhPN.png)](https://asciinema.org/a/Do1FXheRIw5TN05e8FRFmLhPN?autoplay=1)

ArkMongo is a command line utility created to secure MongoDB by utilizing the Ark blockchain.
The utility creates hashes of queries and pushes them onto the blockchain and onto a separate database.
You can then validate each of the hashes to ensure no malicious activity has taken place on the database
and verify interactions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'arkmongo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install arkmongo

## Usage


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guppster/arkmongo. 

## Copyright

Copyright (c) 2018 Gurpreet Singh. See [MIT License](LICENSE.txt) for further details.
