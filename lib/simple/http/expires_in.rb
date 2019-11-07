# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

require "net/http"

class Net::HTTPResponse
  private

  #
  # The "max-age" value, in seconds, from the Cache-Control header.
  def max_age
    return unless (cache_control = header["Cache-Control"])

    cache_control.split(/, /).each do |part|
      next unless part =~ /max-age=(\d+)/

      return Integer($1)
    end
    nil
  end

  public

  #
  # returns expiration information, in seconds from now.
  def expires_in
    expires_in = max_age
    if !expires_in && (expires = header["Expires"])
      expires_in = Time.parse(expires) - Time.now
    end

    return expires_in if expires_in && expires_in > 0
  end
end
