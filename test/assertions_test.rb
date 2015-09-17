# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class SimpleHttpTest < Simple::HTTP::TestCase
  def test_assert_http_error
    assert_http_error(456) do
      http.get "http://eu.httpbin.org/status/456"
    end
  end

  def test_assert_http_redirects_to
    http.follows_redirections = false
    assert_http_redirects_to "http://eu.httpbin.org" do
      http.get "http://eu.httpbin.org/redirect-to?url=http://eu.httpbin.org"
    end
  end
end
