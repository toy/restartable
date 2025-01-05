# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

if RUBY_VERSION >= '3.4'
  require 'date'
  abort 'cucumber should have released the fix' if Date.today >= Date.new(2025, 7, 5)
  gem 'cucumber', github: 'cucumber/cucumber-ruby', ref: '5cec9226789ab1742d5bc36ec3bc194906c58dbc'
end
