require 'rubygems'
require 'bundler/setup'

# require 'simplecov'
require 'test/unit'

# SimpleCov.start do
#   add_filter "test/*.rb"
# end

require 'simple/http'
require 'simple/http/assertions'

class Simple::HTTP::TestCase < Test::Unit::TestCase
  include Simple::HTTP::Assertions

  attr :http

  def setup
    @http = Simple::HTTP.new
  end
end
