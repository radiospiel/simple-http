# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class EchoTest < Simple::HTTP::TestCase
  def test_get
    response = http.get "/echo?a=1&b=2"
    expected = <<~MSG
      GET
      a: 1
      b: 2
    MSG

    assert_equal(expected, response.content)
  end

  def test_head
    response = http.head "/echo?a=1&b=2"
    assert_equal(nil, response.content)
    assert_equal(200, response.status)
  end

  def body_example
    {
      foo: "bar"
    }
  end

  def test_post
    response = http.post "/echo?a=1&b=2", body_example
    expected = <<~MSG
      POST
      a: 1
      b: 2
      CONTENT_TYPE: application/json
      {"foo":"bar"}
    MSG

    assert_equal(expected, response.content)
  end

  def test_put
    response = http.put "/echo?a=1&b=2", body_example
    expected = <<~MSG
      PUT
      a: 1
      b: 2
      CONTENT_TYPE: application/json
      {"foo":"bar"}
    MSG

    assert_equal(expected, response.content)
  end

  def test_delete
    response = http.delete "/echo?a=1&b=2"
    expected = <<~MSG
      DELETE
      a: 1
      b: 2
    MSG

    assert_equal(expected, response.content)
  end
end
