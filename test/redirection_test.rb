# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class RedirectionTest < Simple::HTTP::TestCase
  def test_follows_redirections
    html = http.get "http://eu.httpbin.org/redirect-to?url=http://eu.httpbin.org"
    assert_match(/title.*httpbin/, html)
  end

  def test_raises_error_on_invalid_redirect_location
    assert_raise(ArgumentError) {
      http.get "http://eu.httpbin.org/redirect-to?url=foo"
    }
  end
end
