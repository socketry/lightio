source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in lightio.gemspec
gemspec

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
end

group :test do
  gem 'coveralls', require: false
end

