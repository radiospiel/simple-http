# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

module Simple; end
class Simple::HTTP; end

class Simple::HTTP::Error < RuntimeError
  attr_reader :method, :request, :response

  def initialize(method, request, response)
    @method, @request, @response = method, request, response
  end

  def code
    response.code.to_i
  end

  def message
    message = "#{method} #{response.uri} ##{response.code} #{response.message}"
    if response.is_a?(Net::HTTPRedirection)
      message += " To #{response["Location"]}"
    end
    message
  end
end

class Simple::HTTP::TooManyRedirections < Simple::HTTP::Error
  def message
    "Too many redirections; after\n#{super}"
  end
end
