class Simple::HTTP::Request
  attr_reader :verb, :url, :body, :headers

  class << self
    def build(verb:, url:, body: nil, headers:)
      if body_permitted?(verb) && !headers.key?("Content-Type")
        if body.is_a?(Hash) || body.is_a?(Array)
          headers["Content-Type"] = "application/json"
          body = JSON.generate(body)
        end
      end

      new verb, url, body, headers
    end

    private

    def body_permitted?(verb)
      return false if verb == :GET
      return false if verb == :HEAD
      return false if verb == :DELETE
      return false if verb == :OPTIONS

      true
    end
  end

  private

  def initialize(verb, url, body, headers)
    @verb, @url, @body, @headers = verb, url, body, headers
  end

  public

  def to_s
    scrubbed_url = url.gsub(/\/\/(.*):(.*)@/) { |_| "//#{$1}:xxxxxx@" }
    "#{verb} #{scrubbed_url}"
  end
end
