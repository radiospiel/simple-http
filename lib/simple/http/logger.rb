require "logger"

class Simple::HTTP
  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new(STDERR, level: :warn)
end
