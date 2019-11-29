# This file is part of the simple-http ruby gem.
#
# Copyright (c) 2011 - 2015 @radiospiel
# Distributed under the terms of the modified BSD license, see LICENSE.BSD

module Simple; end
class Simple::HTTP
  module GemHelper
    extend self

    def version(name)
      spec = Gem.loaded_specs[name]
      version = spec ? spec.version.to_s : "0.0.0"
      version += "+unreleased" if !spec || unreleased?(spec)
      version
    end

    private

    def unreleased?(spec)
      return false unless defined?(Bundler::Source::Gemspec)
      return true if spec.source.is_a?(::Bundler::Source::Gemspec)
      return true if spec.source.is_a?(::Bundler::Source::Path)

      false
    end
  end

  VERSION = GemHelper.version "simple-http"
end
