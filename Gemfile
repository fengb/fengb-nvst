source 'https://rubygems.org'

gem 'rails'

# Server
gem 'puma', require: false
gem 'rufus-scheduler', require: false

# Jobs
gem 'yahoo-finance', require: false
gem 'git', require: false

# Model
gem 'pg', platforms: :ruby
gem 'activerecord-jdbc-adapter', platform: :jruby
gem 'jdbc-postgres', platform: :jruby
gem 'devise'
gem 'rails_admin'
gem 'enumerize'
gem 'arlj'

# View
gem 'haml-rails'
gem 'jbuilder'

# Assets
gem 'sass-rails'
gem 'uglifier'
#Server can has node
# gem 'therubyracer', platforms: :ruby
# gem 'therubyrhino', platforms: :jruby

group :development, :test do
  gem 'bullet'
  gem 'did_you_mean'
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'ffaker'
  gem 'pry'
  gem 'big_decimal_helper'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', platforms: :ruby
  gem 'spring', platforms: :ruby
  gem 'spring-commands-rspec', platforms: :ruby
end

group :test do
  gem 'codeclimate-test-reporter', require: false
  gem 'simplecov', require: false
  gem 'spidr'
end
