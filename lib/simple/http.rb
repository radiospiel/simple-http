# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize

require "json"
require "expectation"

module Simple; end
class Simple::HTTP; end

require_relative "http/version"
require_relative "http/helpers"
require_relative "http/caching"
require_relative "http/errors"
require_relative "http/logger"
require_relative "http/headers"
require_relative "http/request"
require_relative "http/response"
require_relative "http/checked_response"

Simple::HTTP.extend Simple::HTTP::Helpers

#
# A very simple, Net::HTTP-based HTTP client.
#
# Has some support for transferring JSON data: all data in PUT and POST
# requests are jsonized, and all data in responses are parsed as JSON if
# the Content-Type header is set to "application/json".
class Simple::HTTP
  #
  # The base URL when set, all requests that do not start with http: or
  # https: are done relative to this base URL.
  attr_accessor :base_url

  #
  # When set (default), redirections are followed. Note: When
  # follows_redirections is not set, a HTTP redirection would raise an
  # error - which is probably only useful when testing an interface.
  attr_accessor :follows_redirections

  #
  # Always send these headers.
  attr_reader :default_headers

  def default_headers=(default_headers)
    expect! default_params => [Hash, nil]
    @default_headers = default_headers
  end

  #
  # When set, appends this to all request URLs
  attr_reader :default_params

  def default_params=(default_params)
    expect! default_params => [Hash, String, nil]
    @default_params = default_params
  end

  #
  # When set, sets Authorization headers to all requests. Must be an
  # array [ username, password ].
  attr_accessor :basic_auth

  def initialize(base_url: nil)
    self.default_headers = {}
    self.default_params = nil
    self.base_url = base_url
    self.follows_redirections = true
  end

  def head(url, headers = {})
    perform_request!(:HEAD, url, nil, headers)
  end

  def get(url, headers = {})
    perform_request!(:GET, url, nil, headers)
  end

  def options(url, headers = {})
    perform_request!(:OPTIONS, url, nil, headers)
  end

  def post(url, body = nil, headers = {})
    perform_request!(:POST, url, body, headers)
  end

  def put(url, body = nil, headers = {})
    perform_request!(:PUT, url, body, headers)
  end

  def delete(url, headers = {})
    perform_request!(:DELETE, url, nil, headers)
  end

  # adds get!, post!; etc.
  include CheckedResponse

  #
  # -- Caching ----------------------------------------------------------------

  # When set, and a response is cacheable (as it returns a valid expires_in
  # value), the cache object is used to cache responses.
  attr_accessor :cache

  # -- HTTP request -----------------------------------------------------------

  def perform_request!(verb, url, body, headers)
    #
    # normalize url; i.e. prepend base_url if the url itself is incomplete.
    unless url =~ /^(http|https):/
      url = File.join(base_url, url)
    end

    expect! url => /^http|https/

    if default_headers
      headers = headers.merge(default_headers)
    end

    case default_params
    when Hash then url = ::Simple::HTTP.build_url(url, default_params)
    when String then url = url + (url.include?("?") ? "&" : "?") + default_params
    end

    request = Request.build(verb: verb, url: url, body: body, headers: headers)

    execute_request(request)
  end

  private

  def execute_request(request, max_redirections: 10)
    response = execute_request_w_caching(request)

    return response unless response.status >= 300 && response.status <= 399
    return response unless follows_redirections

    raise ::Simple::HTTP::TooManyRedirections, response if max_redirections <= 0

    request = ::Simple::HTTP::Request.build(verb: :GET, url: response.headers["Location"], headers: {})
    execute_request(request, max_redirections: max_redirections - 1)
  end

  def execute_request_w_caching(request)
    is_cacheable = request.verb == :GET && cache

    if is_cacheable && (cached = Caching.fetch(request))
      return cached
    end

    response = execute_request_w_logging(request)

    expires_in = Caching.determine_expires_in(response)
    if is_cacheable && expires_in
      Caching.store(request, response, expires_in: expires_in)
    end

    response
  end

  def execute_request_w_logging(request)
    started_at = Time.now

    Simple::HTTP.logger.debug do
      "> #{request}, w/headers #{request.headers}"
    end

    response_hsh = driver.execute_request(request, client: self)

    status, message, headers, body = response_hsh.values_at :status, :message, :headers, :body

    response = ::Simple::HTTP::Response.build request: request,
                                              status: status,
                                              message: message,
                                              body: body,
                                              headers: headers

    ::Simple::HTTP.logger.info do
      # FIXME: for some reason the status message might contain a trailing space?
      message = response.message.gsub(/ $/, "")
      "#{request} #{response.status} #{"%.3f" % (Time.now - started_at)} secs: #{message}"
    end

    response
  end

  def determine_driver
    "default"

    #   require "faraday"
    #   "faraday"
    # rescue LoadError
    #   "default"
  end

  def driver
    @driver ||= begin
      driver_name = determine_driver
      Simple::HTTP.logger.debug "simple-http: Using #{driver_name} driver"
      driver_name
    end

    case @driver
    when "faraday"
      require "simple/http/driver/faraday"
      ::Simple::HTTP::Driver::Faraday
    when "default"
      require "simple/http/driver/default"
      ::Simple::HTTP::Driver::Default
    else
      raise "Internal error"
    end
  end
end
