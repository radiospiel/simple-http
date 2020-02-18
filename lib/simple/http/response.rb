require_relative "./content_type_parser"

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

  ContentTypeParser = Simple::HTTP::ContentTypeParser

  attr_reader :request
  attr_reader :status
  attr_reader :message
  attr_reader :headers
  attr_reader :body

  # e.g "text/plain"
  attr_reader :media_type

  private

  def initialize(request, body, headers, status, message)
    @request = request
    @headers = headers
    @status  = status
    @message = message

    # evaluate content type header, set media_type and set body encoding.
    ctp = ContentTypeParser.new(headers["Content-Type"])
    @media_type = ctp.media_type
    @body       = ctp.reencode!(body) if body
  end

  public

  def bytes
    @body ? @body.bytesize : 0
  end

  def to_s
    "#{status} #{message.gsub(/\s+$/, "")} (#{bytes} byte)"
  end

  # evaluate and potentially parse response
  def content(into: nil)
    return parsed_content if into.nil?

    if parsed_content.is_a?(Array)
      parsed_content.map { |entry| convert_into(entry, into: into) }
    else
      convert_into(parsed_content, into: into)
    end
  end

  private

  def convert_into(rec, into:)
    case into
    when :struct
      to_struct(rec)
    else
      into.new rec
    end
  end

  def to_struct(hsh)
    keys = hsh.keys
    values = hsh.values_at(*keys)

    @to_structs ||= {}
    struct = (@to_structs[keys] ||= Struct.new(*keys.map(&:to_sym)))
    struct.new(*values)
  end

  def parsed_content
    return @parsed_content if defined? @parsed_content

    @parsed_content = parse_content
  end

  def parse_content
    case media_type
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
