require_relative "./body_builder"

class Simple::HTTP::Response
  class << self
    def build(request:, body:, headers:, status:, message:)
      unless body_permitted?(request.verb)
        body = nil
      end

      new request, body, headers, status, message
    end

    def body_permitted?(verb)
      return false if verb == :HEAD
      return false if verb == :OPTIONS

      true
    end
  end

  BodyBuilder = Simple::HTTP::BodyBuilder

  attr_reader :request
  attr_reader :status
  attr_reader :message
  attr_reader :headers
  attr_reader :original_body

  private

  def initialize(request, body, headers, status, message)
    @request = request
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
    @original_body&.bytesize || 0
  end

  def to_s
    "#{status} #{message.gsub(/\s+$/, "")} (#{bytes} byte)"
  end

  # evaluate and potentially parse response
  def content(into: nil)
    return parsed_content if into.nil?

    if parsed_content.is_a?(Array)
      parsed_content.map { |entry| into.new entry }
    else
      into.new parsed_content
    end
  end

  private

  def parsed_content
    return @parsed_content if defined? @parsed_content

    @parsed_content = case media_type
                      when "application/json"
                        body.empty? ? nil : JSON.parse(body)
                      else
                        body
    end
  end

  public

  def checked_content(into:)
    check_response_status!
    content(into: into)
  end

  private

  SUCCESSFUL_STATUS_CODES = 200..299

  def check_response_status!
    return if SUCCESSFUL_STATUS_CODES.include?(status)

    Simple::HTTP.logger.warn do
      msg = "#{request}: HTTP request failed w/#{self}"
      msg += "\nheaders: #{headers}" if Simple::HTTP.logger.debug?
      msg += "\nresponse body: #{body}" if body && Simple::HTTP.logger.info?
      msg
    end

    ::Simple::HTTP::StatusError.raise(response: self)
  end
end
