class Simple::HTTP::Headers < Hash
  def initialize(headers)
    case headers
    when Net::HTTPHeader
      headers.each_name.map do |name|
        values = headers.get_fields(name)
        self[name] = values.length == 1 ? values.first : values
      end
    else
      headers.each do |name, value|
        self[name] = value
      end
    end
  end

  def [](key)
    super key.downcase
  end

  def value(key)
    values(key)&.first
  end

  def values(key)
    v = self[key]
    Array(v) if v
  end

  private

  def []=(key, value)
    super key.downcase, value
  end
end
