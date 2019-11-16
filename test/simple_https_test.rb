# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

ENV['SSL_CERT_FILE'] = '/usr/local/etc/openssl/certs/cert.pem'

require_relative 'test_helper'

class SimpleHttpsTest < Simple::HTTP::TestCase
  def skipped_test_https
    response = http.get "https://google.com"
    assert_match(/doctype/, response)
  end
end
