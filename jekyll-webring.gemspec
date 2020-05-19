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
	spec.homepage      = "https://github.com/syldexiahime/jekyll-webring"
	spec.license       = "GPL-3.0+"
	
	spec.files         = `git ls-files -z`.split("\x0")
	spec.require_paths = ["lib"]
	
	spec.required_ruby_version = ">= 2.3.0"
	
	spec.add_runtime_dependency "jekyll"
	spec.add_runtime_dependency "sanitize"
	spec.add_runtime_dependency "feedjira"
	spec.add_runtime_dependency "httparty"
	
	spec.add_development_dependency "bundler"
end
