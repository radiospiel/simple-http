# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require "net/http"
require "json"
require "logger"

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module Simple; end
class Simple::HTTP; end

require_relative "http/version"
require_relative "http/expires_in"
require_relative "http/errors"
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

    # append default_params, if set
    if default_params
      url.concat(url.include?("?") ? "&" : "?")
      url.concat default_params
    end

    # "raw" execute request
    execute_request verb, url, body, headers
  end

  private

  # rubocop:disable Metrics/MethodLength

  #
  # do a HTTP request, return its response or, when not successful,
  # raise an error.
  def execute_request(verb, url, body, headers, max_redirections = 10)
    unless REQUEST_CLASSES.key?(verb)
      raise ArgumentError, "Invalid verb #{verb.inspect}"
    end

    if verb == :GET && cache && (result = cache.read(url))
      logger.debug "#{verb} #{url}: using cached result"
      return result
    end

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP)
      raise ArgumentError, "Invalid URL: #{url}"
    end

    client = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      client.use_ssl = true
      client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    #
    # build request
    request = build_request verb, uri, body, headers

    #
    # execute request
    started_at = Time.now
    response = client.request(request)
    response_size = response.body&.bytesize || 0
    logger.info "#{verb} #{url}: #{response_size} byte, #{"%.3f secs" % (Time.now - started_at)}"

    #
    # Most of the times Net::HTTP#request returns a response with the :uri
    # attribute set, but sometimes not. We  make sure that the uri is set
    # everytime.
    response.uri = uri

    # Keep the request
    # response.request = request

    #
    # handle redirections. Note that this results in a NEW response object.
    if response.is_a?(Net::HTTPRedirection) && follows_redirections
      if max_redirections <= 0
        raise TooManyRedirections, response
      end

      return execute_request(:GET, response["Location"], nil, {}, max_redirections - 1)
    end

    # #
    # # [TODO] caching
    # # handle successful responses.
    # if response.is_a?(Net::HTTPSuccess)
    #   # result = response.result
    #   if cache && verb == :GET && response.expires_in
    #     logger.debug "#{verb} #{url}: store in cache, w/expiration of #{response.expires_in}"
    #     cache.write(url, result, expires_in: response.expires_in)
    #   end
    #
    #   return response
    # end

    ::Simple::HTTP::Response.build request: request, response: response
  end

  # rubocop:disable Style/HashSyntax, Layout/AlignHash
  REQUEST_CLASSES = {
    :HEAD   =>  Net::HTTP::Head,
    :GET    =>  Net::HTTP::Get,
    :POST   =>  Net::HTTP::Post,
    :PUT    =>  Net::HTTP::Put,
    :DELETE =>  Net::HTTP::Delete
  }.freeze #:nodoc:

  #
  # build a HTTP request object.
  def build_request(method, uri, body, _headers)
    klass = REQUEST_CLASSES.fetch(method)
    request = klass.new(uri.request_uri)

    if uri.user
      request.basic_auth(uri.user, uri.password)
    elsif basic_auth
      request.basic_auth(*basic_auth)
    end

    # set request headers
    # unless headers && !headers.empty?
    #   # TODO: set headers
    #   # set_request_headers request, headers
    # end

    # set request body
    if request.request_body_permitted? && body
      request.content_type = "application/json"
      if body.is_a?(Hash) || body.is_a?(Array)
        body = JSON.generate(body)
      end
      request.body = body
    end

    request
  end
end
