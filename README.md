# simple-http

A really simple HTTP client

- GET, POST, PUT, DELETE

        require "simple/http"
        http_client = Simple::HTTP.new
        http_client.get "http://google.com" # returns a string

- Exceptions on errors: because, after all, when you consume a HTTP endpoint and don't
  get a success (20x), then this is an error. Handle it!

        require "simple/http"
        http_client = Simple::HTTP.new
        begin
          http_client.get "http://google.com" # returns a string
        rescue Simple::HTTP::Error
          STDERR.puts "Ooops! #{$!}"
        end
 
- Caching

        require "simple/http"
        http_client = Simple::HTTP.new

        require "active_support/cache"
        require "active_support/cache/file_store"
        http_client.cache = ActiveSupport::Cache::FileStore.new("var/cache")
        http_client.get "http://google.com" # returns a, potentially, cached string

- Automatic de/encoding of JSON payloads

- Does not requires anything except core ruby classes.