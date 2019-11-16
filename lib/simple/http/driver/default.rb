# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module Simple::HTTP::Driver
end

module Simple::HTTP::Driver::Default
  extend self

  #
  # do a HTTP request, return its response or, when not successful,
  # raise an error.
  def execute_request(request, client:)
    verb, url, body, headers =
      request.verb, request.url, request.body, request.headers

    uri = URI.parse(url)

    # build Net::HTTP request
    request = build_request verb, uri, body, headers, client: client

    # execute request
    net_http = load_net_http(uri.scheme, uri.host, uri.port)
    resp = net_http.request(request)

    ::Simple::HTTP::Response.new request: request,
                                 status: Integer(resp.code),
                                 message: resp.message,
                                 headers: Simple::HTTP::Headers.new(resp),
                                 body: resp.body
  end

  private

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
  def build_request(method, uri, body, _headers, client:)
    klass = REQUEST_CLASSES.fetch(method)
    request = klass.new(uri.request_uri)

    if uri.user
      request.basic_auth(uri.user, uri.password)
    elsif client.basic_auth
      request.basic_auth(*client.basic_auth)
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

  def load_net_http(scheme, host, port)
    net_http = Net::HTTP.new(host, port)
    if scheme == "https"
      net_http.use_ssl = true
      net_http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    net_http
  end
end
