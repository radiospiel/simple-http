class Simple::HTTP::Request
  attr_reader :verb, :url, :body, :headers

  def initialize(verb:, url:, body: nil, headers:)
    @verb, @url, @body, @headers = verb, url, body, headers
  end

  def to_s
    scrubbed_url = url.gsub(/\/\/(.*):(.*)@/) { |_| "//#{$1}:xxxxxx@" }
    "#{verb} #{scrubbed_url}"
  end
end
