# rubocop:disable Metrics/AbcSize

module Simple::HTTP::Driver
end

module Simple::HTTP::Driver::Faraday
  extend self

  URI_KLASSES = {
    "http" => URI::HTTP,
    "https" => URI::HTTPS
  }

  # does an HTTP request and returns its response.
  def execute_request(request, client:)
    connection = build_connection(request.url, client: client)

    headers = request.headers.dup

    body = request.body

    resp = connection.run_request(request.verb.downcase, request.url, body, headers)

    {
      status: Integer(resp.status),
      message: resp.reason_phrase,
      headers: Simple::HTTP::Headers.new(resp.headers.to_hash),
      body: resp.body
    }
  end

  private

  def build_connection(url, client:)
    ::Faraday.new.tap do |connection|
      uri = URI.parse(url)
      if uri.user
        connection.basic_auth(uri.user, uri.password)
      elsif client.basic_auth
        connection.basic_auth(*client.basic_auth)
      end
    end
  end
end
