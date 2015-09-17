# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class SimpleHttpTest < Simple::HTTP::TestCase
  def test_http_google
    google = http.get "http://google.com"
    assert_match(/doctype/, google)
  end

  def test_https_google
    google = http.get "https://google.com"
    assert_match(/doctype/, google)
  end
end
