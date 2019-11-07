# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

require "net/http"

class Net::HTTPResponse
  #
  # evaluate and potentially parse response
  def result
    case content_type
    when "application/json"
      JSON.parse(body) unless body.empty?
    else
      body_string
    end
  end

  private

  #
  # returns a body. The resulting string is encoded in ASCII-8BIT, if the 
  # content type is binary, and encoded in UTF8 otherwise.
  def body_string
    return nil unless self.body # e.g. HEAD

    default_encoding = content_is_binary? ? "ASCII-8BIT" : "UTF-8"

    body = self.body
    if charset = type_params["charset"]
      body = body.force_encoding(charset)
    end
    body.encode(default_encoding)
  end

  def content_is_binary?
    case content_type
    when /^image/ then true
    else false
    end
  end
end
