# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

source "https://rubygems.org"

gemspec

group :development, :test do
  gem 'pry-byebug'
  gem 'rake'
  gem 'test-unit'

  gem "rspec-httpd", "~> 0.1"
  # gem 'rspec-httpd', path: "../rspec-httpd", require: false

  gem 'simple-httpd', "~> 0.3.3"
  # gem 'simple-httpd', path: "../simple-httpd", require: false

  gem "simplecov", require: false
end

ENV["PRELOAD_GEMS"].to_s.split(",").each do |gem_name|
  gem gem_name
end
