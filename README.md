# DopCommon

This gem is part of the Deployment and Orchestration for Puppet
or DOP for short. dop_common is a library for the parsing and
validation of DOP plan files.

## Installation

Add this line to your application's Gemfile:

    gem 'dop_common'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dop_common

## Usage

TODO: Write usage instructions here

## DOP Plan Format

[DOP Plan Format v 0.0.1](doc/plan_format_v0.0.1.md)

## Tests

To run the tests for your current machine run:

    $ bundle install
    $ bundle exec rake

To run the tests on all the supportet platform you will need
a vagrant installation with virtualbox.

    $ bundle install
    $ bundle exec rake vagrant:spec

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
