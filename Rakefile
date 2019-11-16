# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

$:.unshift File.expand_path("../lib", __FILE__)

require "bundler/setup"

Dir.glob("tasks/*.rake").sort.each do |task|
  load task
end

desc "Release a new gem version"
task :release do
  sh "scripts/release"
end

task :test do
  Dir.glob("test/*_test.rb").sort.each do |path|
    load path
  end
end

task :default => :test #, :rdoc]
