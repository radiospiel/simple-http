# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

module Simple::HTTP::Assertions
  def assert_http_error(expected_status, &block)
    http_error = assert_raises(Simple::HTTP::Error, &block)
    assert_equal(expected_status, http_error.code)
  end

  def assert_http_redirects_to(expected_location, &block)
    http_error = assert_raises(Simple::HTTP::Error, &block)
    assert_includes([301, 302], http_error.code)
    assert_equal(expected_location, http_error.response["Location"])
  end
end
