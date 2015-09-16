# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class SimpleHttpTest < Test::Unit::TestCase
  HTTP = Simple::HTTP.new

  def test_loaded
    google = HTTP.get "http://google.com"
    assert_match(/doctype/, google)
  end
end
