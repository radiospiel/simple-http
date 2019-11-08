# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require "net/http"
require "json"
require "logger"

module Simple; end
class Simple::HTTP; end

require_relative "http/version"
require_relative "http/caching"
require_relative "http/errors"
require_relative "http/headers"
require_relative "http/request"
require_relative "http/response"

require "openssl"

#
# A very simple, Net::HTTP-based HTTP client.
#
# Has some support for transferring JSON data: all data in PUT and POST
# requests are jsonized, and all data in responses are parsed as JSON if
# the Content-Type header is set to "application/json".
class Simple::HTTP
  #
  # The logger instance.
  attr_accessor :logger

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
  # When set, appends this to all request URLs
  attr_accessor :default_params

  #
  # When set, sets Authorization headers to all requests. Must be an
  # array [ username, password ].
  attr_accessor :basic_auth

  def initialize
    self.follows_redirections = true
    self.logger = Logger.new(STDERR, level: :warn)
  end

  def head(url, headers = {})
    request :HEAD, url, nil, headers
  end

  def get(url, headers = {})
    request :GET, url, nil, headers
  end

  def post(url, body = nil, headers = {})
    request :POST, url, body, headers
  end

  def put(url, body = nil, headers = {})
    request :PUT, url, body, headers
  end

  def delete(url, headers = {})
    request :DELETE, url, nil, headers
  end

  #
  # -- Caching ----------------------------------------------------------------

  # When set, and a response is cacheable (as it returns a valid expires_in
  # value), the cache object is used to cache responses.
  attr_accessor :cache

  # -- HTTP request -----------------------------------------------------------

  def request(verb, url, body, headers)
    #
    # normalize url; i.e. prepend base_url if the url itself is incomplete.
    unless url =~ /^(http|https):/
      url = File.join(base_url, url)
    end

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP)
      raise ArgumentError, "Invalid URL: #{url}"
    end

    # append default_params, if set
    if default_params
      url.concat(url.include?("?") ? "&" : "?")
      url.concat default_params
    end

    request = Request.new(verb: verb, url: url, body: body, headers: headers)

    execute_request(request)
  end

  private

  def execute_request(request, max_redirections: 10)
    response = execute_request_w_caching(request)

    return response unless response.status >= 300 && response.status <= 399
    return response unless follows_redirections

    raise ::Simple::HTTP::TooManyRedirections, response if max_redirections <= 0

    request = ::Simple::HTTP::Request.new(verb: :GET, url: response.headers["Location"], headers: {})
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

    response = driver.execute_request(request, client: self)

    logger.info do
      "#{request}: #{response}, #{"%.3f secs" % (Time.now - started_at)}"
    end

    response
  end

  def driver
    require "simple/http/driver/default"
    ::Simple::HTTP::Driver::Default
  end
end
