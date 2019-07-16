# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-webring/version"

Gem::Specification.new do |spec|
	spec.name          = "jekyll-webring"
	spec.version       = Jekyll::Webring::VERSION
	spec.authors       = ["Sophie Askew"]
	spec.email         = ["sophie@ofthewi.red"]
	spec.summary       = "A Jekyll plugin to generate a webring from rss feeds"
	spec.homepage      = "https://git.sr.ht/~syldexia/jekyll-webring"
	spec.license       = "GNU GPLv3"
	
	spec.files         = `git ls-files -z`.split("\x0")
	spec.test_files    = spec.files.grep(%r!^spec/!)
	spec.require_paths = ["lib"]
	
	spec.required_ruby_version = ">= 2.3.0"
	
	spec.add_runtime_dependency "jekyll"
	spec.add_runtime_dependency "abbreviato"
	spec.add_runtime_dependency "sanitize"
	
	spec.add_development_dependency "bundler"
end
