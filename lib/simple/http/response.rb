# rubocop:disable Metrics/ParameterLists

class Simple::HTTP::Response
  attr_reader :request
  attr_reader :status
  attr_reader :message
  attr_reader :headers
  attr_reader :body
  attr_reader :content_type

  def initialize(request:, body:, headers:, status:, message:, content_type:, bytes: 0)
    @request, @headers = request, headers
    @status, @message = status, message
    @body, @content_type = body, content_type
    @bytes = bytes
  end

  def to_s
    "#{status} #{message.gsub(/\s+$/, "")} (#{bytes} byte)"
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
end
