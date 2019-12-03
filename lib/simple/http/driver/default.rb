# rubocop:disable Metrics/AbcSize

module Simple::HTTP::Driver
end

module Simple::HTTP::Driver::Default
  extend self

  # does an HTTP request and returns its response.
  def execute_request(request, client:)
    verb, url, body, headers =
      request.verb, request.url, request.body, request.headers

    uri = URI.parse(url)

    # build Net::HTTP request
    net_request = build_request verb, uri, body, headers, client: client

    # execute request
    net_http = load_net_http(uri.scheme, uri.host, uri.port)
    response = net_http.request(net_request)

    {
      status: Integer(response.code),
      message: response.message,
      headers: Simple::HTTP::Headers.new(response),
      body: response.body
    }
  end

  private

  # rubocop:disable Style/HashSyntax, Layout/AlignHash
  REQUEST_CLASSES = {
    :HEAD   =>  Net::HTTP::Head,
    :GET    =>  Net::HTTP::Get,
    :OPTIONS =>  Net::HTTP::Options,
    :POST   =>  Net::HTTP::Post,
    :PUT    =>  Net::HTTP::Put,
    :DELETE =>  Net::HTTP::Delete
  }.freeze #:nodoc:
  # rubocop:enable Style/HashSyntax, Layout/AlignHash

  #
  # build a HTTP request object.
  def build_request(method, uri, body, headers, client:)
    klass = REQUEST_CLASSES.fetch(method)
    request = klass.new(uri.request_uri)

    if uri.user
      request.basic_auth(uri.user, uri.password)
    elsif client.basic_auth
      request.basic_auth(*client.basic_auth)
    end

    if headers && !headers.empty?
      headers.each { |key, value| request[key] = value }
    end

    request.body = body if body

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
