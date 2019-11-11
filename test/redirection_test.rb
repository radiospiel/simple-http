# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class RedirectionTest < Simple::HTTP::TestCase
  def test_limits_redirections
    assert_raise(Simple::HTTP::TooManyRedirections) {
      http.get "/redirect-to-self"
    }
  end

  def test_follows_redirections
    response = http.get "/redirect-to?url=http://#{HOST}:#{PORT}/redirection-target"
    assert_match(/I am the redirection target/, response.content)
  end

  # We have a hard time to convince the test application to redirect
  # to an invalid location.. we therefore skip this test. 
  def skipped_test_raises_error_on_invalid_redirect_location
    assert_raise(ArgumentError) {
      http.get "/redirect-to?url=foo"
    }
  end
end
