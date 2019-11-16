# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

module Simple::HTTP::Caching
  extend self

  #
  # returns expiration information, in seconds from now.
  def determine_expires_in(response)
    return nil unless cacheable_status?(response.status)

    expires_in = parse_cache_control response
    expires_in ||= parse_expires response

    return expires_in if expires_in && expires_in > 0
  end

  private

  def cacheable_status?(status)
    (status >= 200 && status <= 299) || (status >= 400 && status <= 499)
  end

  # Returns the expiration setting from the "Cache-Control"'s max-age entry
  def parse_cache_control(response)
    cache_control = response.headers["Cache-Control"]
    return unless cache_control

    cache_control.split(/,\s+/).each do |part|
      next unless part =~ /max-age=(\d+)/

      return Integer($1)
    end
    nil
  end

  # Returns the expiration setting from the "Expires" header
  def parse_expires(response)
    expires = response.headers["Expires"]
    return unless expires

    Time.parse(expires) - Time.now
  end
end
