# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require "net/http"
require "json"

module Simple; end
class Simple::HTTP; end

require_relative "http/version"
require_relative "http/result"
require_relative "http/expires_in"
require_relative "http/errors"

#
# A very simple, Net::HTTP-based HTTP client. 
#
# Has some support for transferring JSON data: all data in PUT and POST
# requests are jsonized, and all data in responses are parsed as JSON if
# the Content-Type header is set to "application/json".
class Simple::HTTP

  #
  # The base URL: when set, all requests that do not start with http: or 
  # https: are done relative to this base URL. 
  attr :base_url, true
  
  #
  # When set (default), redirections are followed. Note: When 
  # follows_redirections is not set, a HTTP redirection would raise an
  # error - which is probably only useful when testing an interface.
  attr :follows_redirections, true

  #
  # When set, appends this to all request URLs
  attr :default_params, true

  #
  # When set, sets Authorization headers to all requests. Must be an
  # array [ username, password ].
  attr :basic_auth, true

  def initialize
    self.follows_redirections = true
  end

  def get(url, headers = {});               http :GET, url, nil, headers; end
  def post(url, body = nil, headers = {});  http :POST, url, body, headers; end
  def put(url, body = nil, headers = {});   http :PUT, url, body, headers; end
  def delete(url, headers = {});            http :DELETE, url, nil, headers; end

  #
  # -- Caching ----------------------------------------------------------------

  # When set, and a response is cacheable (as it returns a valid expires_in 
  # value), the cache object is used to cache responses.
  attr :cache, true

  #
  # when does the response expire? By default, calculates expiration based
  # on response headers. Override as needed.
  def expires_in(response)
    response.expires_in
  end

  private

  # -- HTTP request -----------------------------------------------------------

  def http(method, url, body = nil, headers)
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
    http_ method, url, body, headers
  end

  # 
  # do a HTTP request, return its response or, when not successful, 
  # raise an error.
  def http_(method, url, body, headers, max_redirections = 10)
    if method == :GET && cache && result = cache.read(url)
      return result
    end

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP)
      raise ArgumentError, "Invalid URL: #{url}"
    end

    http = Net::HTTP.new(uri.host, uri.port)

    #
    # build request
    request = build_request method, uri, body, headers

    #
    # execute request
    response = http.request(request)
    
    #
    # Most of the times Net::HTTP#request returns a response with the :uri
    # attribute set, but sometimes not. We  make sure that the uri is set 
    # everytime.
    response.uri = uri

    #
    # handle successful responses.
    if response.is_a?(Net::HTTPSuccess)
      result = response.result
      if cache && method == :GET && expires_in = self.expires_in(response)
        cache.write(url, result, expires_in: expires_in)
      end

      return result
    end

    #
    # handle redirections.
    if response.is_a?(Net::HTTPRedirection) && self.follows_redirections
      if max_redirections <= 0
        raise TooManyRedirections.new(method, request, respons)
      end
      
      return http_(:GET, response["Location"], nil, {}, max_redirections - 1)
    end

    #
    # raise an error in any other case.
    raise Error.new(method, request, response)
  end

  private

  REQUEST_CLASSES = {
    :GET    =>  Net::HTTP::Get,
    :POST   =>  Net::HTTP::Post,
    :PUT    =>  Net::HTTP::Put,
    :DELETE =>  Net::HTTP::Delete
  }.freeze #:nodoc:

  #
  # build a HTTP request object.
  def build_request(method, uri, body, headers)
    klass = REQUEST_CLASSES.fetch(method)
    request = klass.new(uri.request_uri)

    if basic_auth
      username, password = *basic_auth
      request.basic_auth(username, password)
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
