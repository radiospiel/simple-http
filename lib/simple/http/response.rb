class Simple::HTTP::Response
  def self.build(response:, request:)
    new(response: response, request: request)
  end

  def initialize(response:, request:)
    @request, @response = request, response
  end

  def headers
    @headers = @response.canonical_each.each_with_object({}) do |(key, value), hsh|
      hsh[key] = value
    end
  end

  def status
    @status ||= Integer(@response.code)
  end

  #
  # evaluate and potentially parses response body.
  # raises an Simple::Http::Error if the result code is not a 2xx
  def result!
    raise Error, self unless status >= 200 && status <= 299

    result
  end

  #
  # evaluate and potentially parse response
  def result
    case content_type
    when "application/json"
      JSON.parse(body) unless body.empty?
    else
      body
    end
  end

  def content_type
    @response.content_type
  end

  #
  # returns a body. The resulting string is encoded in ASCII-8BIT, if the
  # content type is binary, and encoded in UTF8 otherwise.
  def body
    @body = build_body unless defined?(@body)
    @body
  end

  private

  def build_body
    body = @response.body
    return nil unless body # e.g. HEAD

    # type_params: "Any parameters specified for the content type, returned as
    # a Hash. For example, a header of Content-Type: text/html; charset=EUC-JP
    # would result in #type_params returning {'charset' => 'EUC-JP'}"
    if (charset = @response.type_params["charset"])
      body = body.force_encoding(charset)
    end

    body.encode(default_encoding)
  end

  # returns the default encoding for the current response's content type.
  def default_encoding
    # [TODO] review this.
    case content_type
    when /^image/ then "ASCII-8BIT"
    else "UTF-8"
    end
  end
end
