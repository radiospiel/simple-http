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

  def status
    response.status
  end

  def request
    @response.request
  end

  def verb
    request.verb
  end

  def message
    "#{verb} #{request.url} ##{status} #{response.message}"
  end
end

class Simple::HTTP::StatusError < Simple::HTTP::Error
  def self.raise(response:)
    error_klass = case response.status
                  when 400..499 then ::Simple::HTTP::Status4XXError
                  when 500..599 then ::Simple::HTTP::Status5XXError
                  else ::Simple::HTTP::StatusError
    end

    Kernel.raise error_klass.new(response)
  end
end

class Simple::HTTP::Status4XXError < Simple::HTTP::StatusError
end

class Simple::HTTP::Status5XXError < Simple::HTTP::StatusError
end

class Simple::HTTP::TooManyRedirections < Simple::HTTP::Error
  def location
    response["Location"]
  end

  def message
    "#{super}: too many redirections (latest to #{location})"
  end
end
