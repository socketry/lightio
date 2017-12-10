# LightIO


[![Gem Version](https://badge.fury.io/rb/lightio.svg)](http://rubygems.org/gems/lightio)
[![Build Status](https://travis-ci.org/jjyr/lightio.svg?branch=master)](https://travis-ci.org/jjyr/lightio)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jjyr/lightio/blob/master/LICENSE.txt)

LightIO is a ruby networking library, that combines ruby fiber and IO event loop to provide both simple synchrony library interface and high performance networking IO.


LightIO is heavily inspired by [gevent](http://www.gevent.org/).

## Current Status

This library is still **WIP**, *watch* or *star* this repo for further information.
Its not recommendation to use LightIO in production now, but you can always give a try. open a issue if you have any question.

Before we release a full networking framework at the version 1.0.0, there are three targets(milestones).

1. Provide a bare-bone framework, include fiber based lightweight executor and a way to collebrate with ruby socket library
2. Provide lightio networking libraries, that have the same API with ruby stdlib
3. Implement ruby stdlib monkey patch, user can apply monkey patch and just write normal ruby code to get the power of lightio

Thanks to [nio4r](https://github.com/socketry/nio4r), the first target is already achieved.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lightio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lightio

## Usage

``` ruby
require 'lightio'

start = Time.now

beams = 1000.times.map do
  # LightIO::Beam is a thread-like executor, use it instead Thread
  LightIO::Beam.new do
    # do some io operations in beam
    LightIO.sleep(1)
  end
end

beams.each(&:join)
seconds = Time.now - start
puts "1000 beams take #{seconds - 1} seconds to create"
```

View more [examples](/examples).

## Documentation

See [wiki](https://github.com/jjyr/lightio/wiki) for more information

[API Documentation](http://www.rubydoc.info/gems/lightio/frames)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jjyr/lightio. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lightio project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/lightio/blob/master/CODE_OF_CONDUCT.md).
