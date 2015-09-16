$:.unshift File.expand_path("../lib", __FILE__)

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  require "simple/http/version"
  version = Simple::HTTP::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Simple::HTTP #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
