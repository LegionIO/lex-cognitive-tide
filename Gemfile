# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.75', require: false
  gem 'rubocop-rspec', require: false
end

if File.directory?(File.expand_path('../../legion-gaia', __dir__))
  gem 'legion-gaia', path: '../../legion-gaia'
else
  gem 'legion-gaia'
end
