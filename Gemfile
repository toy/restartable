source 'https://rubygems.org'

gemspec

case
when RUBY_VERSION < '1.9.3'
  gem 'cucumber', '< 2'
  gem 'sys-proctable', '<= 1.2.1'
when RUBY_VERSION < '2.0'
  gem 'cucumber', '< 3'
else
  gem 'travis_check_rubies', '~> 0.2'
end
