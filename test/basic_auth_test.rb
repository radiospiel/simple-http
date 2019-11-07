# Author::    radiospiel  (mailto:eno@radiospiel.org)
# Copyright:: Copyright (c) 2011-2015 radiospiel
# License::   Distributes under the terms  of the Modified BSD License, see LICENSE.BSD for details.

require_relative 'test_helper'

class SimpleHttpTest < Simple::HTTP::TestCase
  def test_basic_auth
    http.basic_auth = [ "admin", "secret" ]
    http.get "/basic-auth/user/passwd"
  end

  def test_basic_auth_invalid
    http.basic_auth = [ "wronguser", "passwd" ]
    assert_http_error 401 do
      http.get "/basic-auth/user/passwd"
    end
  end

  def test_basic_auth_missing
    http.basic_auth = [ "wronguser", "passwd" ]
    assert_http_error 401 do
      http.get "/basic-auth/user/passwd"
    end
  end

  def test_url_auth
    http.get "http://admin:secret@#{HOST}:#{PORT}/basic-auth/user/passwd"
  end

  def test_url_auth_overrides_basic_auth
    http.basic_auth = [ "wronguser", "passwd" ]
    http.get "http://admin:secret@#{HOST}:#{PORT}/basic-auth/user/passwd"

    http.basic_auth = [ "admin", "secret" ]
    assert_http_error 401 do
      http.get "http://wrongadmin:secret@#{HOST}:#{PORT}/basic-auth/user/passwd"
    end
  end
end
