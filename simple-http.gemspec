# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

$:.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name     = "simple-http"
  gem.version  = File.read("VERSION")

  gem.author   = "radiospiel"
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/simple-http"
  gem.summary  = "Simple code for simple HTTP requests"

  gem.description = gem.summary

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

  gem.add_runtime_dependency "expectation", "~> 1.1", ">= 1.1.1"
end
