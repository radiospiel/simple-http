# The code in this module was originally taken from rack/media_type.rb
# and modified. We don't include a rack dependency here, since we don't
# want to use a server library in a client tool.

# parses content_type to return media_type and charset.
class Simple::HTTP::ContentTypeParser
  SPLIT_PATTERN = %r{\s*[;,]\s*}

  # The content_type value as being passed in.
  attr_reader :content_type

  # The media type (type/subtype) portion of the CONTENT_TYPE header
  # without any media type parameters. e.g., when CONTENT_TYPE is
  # "text/plain;charset=utf-8", the media-type is "text/plain".
  #
  # For more information on the use of media types in HTTP, see:
  # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7
  attr_reader :media_type

  # The charset as embedded on the Content-Type header
  attr_reader :charset

  def initialize(content_type)
    @content_type = content_type
    @media_type   = content_type.split(SPLIT_PATTERN, 2).first.downcase if content_type
    @charset      = extract_charset_from_content_type if content_type
  end

  # returns the encoding the body is supposed to be encoded as.
  def encoding
    resolve_encoding_name(charset || guess_encoding_name)
  end

  def reencode!(body)
    body.force_encoding(encoding)
    unless body.valid_encoding?
      raise "Invalid payload: body is encoded invalid; encoding is #{content_type_parser.encoding.name}"
    end

    body
  end

  private

  def resolve_encoding_name(str)
    ::Encoding.find(str)
  rescue ArgumentName
    raise "Cannot resolve encoding name #{encoding_name.inspect} from Content-Type: #{content_type.inspect}"
  end

  # This method is being called when there is no charset value in the content_type header.
  def guess_encoding_name
    case media_type
    when /^application\/json/, /^application\/xml/, /^text\// then "UTF-8"
    else "ASCII-8BIT"
    end
  end

  CHARSET_PARAMETER_NAME = "charset"

  # The media type parameters provided in CONTENT_TYPE as a Hash, or
  # an empty Hash if no CONTENT_TYPE or media-type parameters were
  # provided.  e.g., when the CONTENT_TYPE is "text/plain;charset=utf-8",
  # this method responds with the following Hash:
  #   { 'charset' => 'utf-8' }
  def extract_charset_from_content_type
    content_type.split(SPLIT_PATTERN)[1..-1].each do |s|
      k, v = s.split("=", 2)
      next unless k.downcase == CHARSET_PARAMETER_NAME

      return strip_double_quotes(v)
    end

    nil
  end

  def strip_double_quotes(str)
    str = str[1..-2] if str[0] == '"' && str[-1] == '"'
    str
  end
end
