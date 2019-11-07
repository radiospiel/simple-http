# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

module Simple; end
class Simple::HTTP; end

class Simple::HTTP::Error < RuntimeError
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def code
    response.code.to_i
  end

  def request
    @response.request
  end

  def verb
    request.class::METHOD
  end

  def message
    "#{verb} #{request.uri} ##{response.code} #{response.message}"
  end
end

class Simple::HTTP::TooManyRedirections < Simple::HTTP::Error
  def location
    response["Location"]
  end

  def message
    "#{super}: too many redirections (latest to #{location})"
  end
end
