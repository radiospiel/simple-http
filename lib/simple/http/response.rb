require_relative "./body_builder"

class Simple::HTTP::Response
  BodyBuilder = Simple::HTTP::BodyBuilder

  attr_reader :request
  attr_reader :status
  attr_reader :message
  attr_reader :headers
  attr_reader :original_body

  def initialize(body:, headers:, status:, message:)
    @headers = headers
    @status = status
    @message = message
    @original_body = body

    # adjust encoding on original_body
    @body_builder = BodyBuilder.new(headers["Content-Type"])

    if @original_body && (charset = @body_builder.charset)
      @original_body.force_encoding(charset)
    end
  end

  private

  def set_request(request)
    @request = request
  end

  public

  # e.g "text/plain"
  def media_type
    @body_builder.media_type
  end

  # returns the body
  #
  # This method reencodes the text body into UTF-8. Non-text bodies should be
  # encoded as ASCII-8BIT (a.k.a. "BINARY")
  def body
    @body ||= @body_builder.reencode(@original_body)
  end

  def bytes
    @original_body&.byte_size || 0
  end

  def to_s
    "#{status} #{message.gsub(/\s+$/, "")} (#{bytes} byte)"
  end

  # evaluate and potentially parses response body.
  # raises an Simple::Http::Error if the result code is not a 2xx
  def content!
    raise Error, self unless status >= 200 && status <= 299

    content
  end

  # evaluate and potentially parse response
  def content
    case media_type
    when "application/json"
      JSON.parse(body) unless body.empty?
    else
      body
    end
  end
end
