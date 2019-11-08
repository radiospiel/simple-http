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
                                 headers: build_headers(resp),
                                 body: body_w_correct_encoding(resp),
                                 content_type: resp.content_type,
                                 bytes: (resp.body&.bytesize || 0)
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

  def build_headers(resp)
    resp.canonical_each.each_with_object({}) do |(key, value), hsh|
      hsh[key] = value
    end
  end

  # [TODO] review this.
  # returns a body string, with either ASCII-8BIT or UTF8 encoding.
  def body_w_correct_encoding(response)
    body = response.body
    return nil unless body # e.g. HEAD

    # type_params: "Any parameters specified for the content type, returned as
    # a Hash. For example, a header of Content-Type: text/html; charset=EUC-JP
    # would result in #type_params returning {'charset' => 'EUC-JP'}"
    if (charset = response.type_params["charset"])
      body = body.force_encoding(charset)
    end

    default_encoding = case response.content_type
                       when /^image/ then "ASCII-8BIT"
                       else "UTF-8"
                       end

    body.encode(default_encoding)
  end
end
