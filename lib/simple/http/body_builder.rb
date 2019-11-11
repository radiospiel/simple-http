# This module originally was taken from rack/media_type.rb and modified:
# we don't want to have a rack (which is a server toolset) dependency
# in simple-http, which is a client after all.

# parses content_type to return media_type and charset, and can reencode bodies.
class Simple::HTTP::BodyBuilder
  SPLIT_PATTERN = %r{\s*[;,]\s*}

  def initialize(content_type)
    @media_type = content_type.split(SPLIT_PATTERN, 2).first.downcase if content_type
    @charset = fetch_content_type_param(content_type, "charset", default: nil)
  end

  # The media type (type/subtype) portion of the CONTENT_TYPE header
  # without any media type parameters. e.g., when CONTENT_TYPE is
  # "text/plain;charset=utf-8", the media-type is "text/plain".
  #
  # For more information on the use of media types in HTTP, see:
  # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7
  attr_reader :media_type

  # The charset as embedded on the Content-Type header
  attr_reader :charset

  # returns the body
  #
  # This method reencodes the text body into UTF-8. Non-text bodies should be
  # encoded as ASCII-8BIT (a.k.a. "BINARY")
  def reencode(body)
    body&.encode(best_encoding)
  end

  private

  BINARY = ::Encoding.find "ASCII-8BIT"
  UTF8 = ::Encoding.find "UTF-8"

  # returns the encoding we want for the body.
  #
  # This method makes sure to reencode text bodies into UTF-8, and non-text
  # bodies as ASCII-8BIT (a.k.a. "BINARY")
  def best_encoding
    case media_type
    when /^application\/json/, /^application\/xml/, /^text\// then UTF8
    else BINARY
    end
  end

  # The media type parameters provided in CONTENT_TYPE as a Hash, or
  # an empty Hash if no CONTENT_TYPE or media-type parameters were
  # provided.  e.g., when the CONTENT_TYPE is "text/plain;charset=utf-8",
  # this method responds with the following Hash:
  #   { 'charset' => 'utf-8' }
  def fetch_content_type_param(content_type, parameter_name, default:)
    return default if content_type.nil?

    parameter_name = parameter_name.downcase

    content_type.split(SPLIT_PATTERN)[1..-1]
                .each do |s|
      k, v = s.split("=", 2)
      return strip_doublequotes(v) if k.downcase == parameter_name
    end

    default
  end

  def strip_doublequotes(str)
    str[0] == '"' && str[-1] == '"' ? str[1..-2] : str
  end
end
