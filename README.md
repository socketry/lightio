# LightIO


[![Gem Version](https://badge.fury.io/rb/lightio.svg)](http://rubygems.org/gems/lightio)
[![Build Status](https://travis-ci.org/socketry/lightio.svg?branch=master)](https://travis-ci.org/socketry/lightio)
[![Coverage Status](https://coveralls.io/repos/github/socketry/lightio/badge.svg?branch=master)](https://coveralls.io/github/socketry/lightio?branch=master)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jjyr/lightio/blob/master/LICENSE.txt)

LightIO provide green thread to ruby. Like Golang's goroutine, or Crystal's fiber. In LightIO it called beam. 

LightIO ship ruby stdlib compatible library under `LightIO` or `LightIO::Library` namespace, 
these libraries provide ability to schedule LightIO beams when IO operations occur.

see [Examples](/examples) for detail.

LightIO also provide a monkey patch, it replace ruby `Thread` with `LightIO::Thread`, and also replace `IO` related classes.

Example:

``` ruby
LightIO::Monkey.patch_all!
# now you can just write normal ruby code
start = Time.now
10.times.map do
  Thread.new do
    `sleep 1`
  end
end.each(&:join)
puts Time.now - start

``` 

### You Should Know

In fact ruby core team already plan to implement `Thread::Green` in core language, see https://bugs.ruby-lang.org/issues/13618

It mean if ruby implemented `Thread::Green`, this library is no meaning to exists.
But as a crazy userland implemented green thread library, it bring lot's of fun to me, so I will continue to maintain it, and welcome to use  


See [Wiki](https://github.com/jjyr/lightio/wiki) and [Roadmap](https://github.com/jjyr/lightio/wiki/Current-status-and-roadmap) to get more information.

LightIO is build upon [nio4r](https://github.com/socketry/nio4r). Get heavily inspired by [gevent](http://www.gevent.org/), [async-io](https://github.com/socketry/async-io).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lightio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lightio

## Documentation

[Please see LightIO Wiki](https://github.com/jjyr/lightio/wiki) for more information.

The following documentations is also usable:

* [Basic usage](https://github.com/socketry/lightio/wiki/Basic-Usage)
* [YARD documentation](http://www.rubydoc.info/github/socketry/lightio/master)
* [Examples](/examples)

## Discussion

https://groups.google.com/group/lightio

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jjyr/lightio. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Copyright, 2017-2018, by [Jiang Jinyang](http://justjjy.com/)

## Code of Conduct

Everyone interacting in the Lightio project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/lightio/blob/master/CODE_OF_CONDUCT.md).
