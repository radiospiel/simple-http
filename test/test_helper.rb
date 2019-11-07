require 'rubygems'
require 'bundler/setup'

# -- setup a test server serving ./test/fixtures/httpd ------------------------
#
# This server uses simple-httpd to serve some static and dynamic test content.
# Note: for purity reasons this should be reimplemented  via a rack middleware.
#
$: << "../rspec-httpd/lib"
require "rspec/httpd/server"

require 'test/unit'

# require 'simplecov'
#
# SimpleCov.start do
#   add_filter "test/*.rb"
# end

require 'simple/http'

class Simple::HTTP::TestCase < Test::Unit::TestCase
  HOST = "0.0.0.0"
  PORT = 12345

  attr :http

  # start a test server. Note that this starts the server only once, and
  # automatically cleans up the server when this process finishes.
  def start_server!
    httpd_root = "#{__dir__}/fixtures/httpd"

    # The command to start the server must reset the BUNDLE_GEMFILE environment
    # setting.
    command = "cd ../simple-httpd/ && BUNDLE_GEMFILE= bin/simple-httpd --port=12345 #{httpd_root} -q" 
    command = "#{command} 2> log/simple-httpd.log" 

    ::RSpec::Httpd::Server.start! port: PORT, command: command
  end

  def setup
    start_server!

    @http = Simple::HTTP.new
    @http.base_url = "http://#{HOST}:#{PORT}"
  end

  def assert_http_error(expected_status, &block)
    http_error = assert_raises(Simple::HTTP::Error, &block)
    assert_equal(expected_status, http_error.code)
  end

  def assert_http_redirects_to(expected_location, &block)
    http_error = assert_raises(Simple::HTTP::Error, &block)
    assert_includes([301, 302], http_error.code)
    assert_equal(expected_location, http_error.response["Location"])
  end
end
