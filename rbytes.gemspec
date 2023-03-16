# frozen_string_literal: true

require_relative "lib/ruby_bytes/version"

Gem::Specification.new do |s|
  s.name = "rbytes"
  s.version = RubyBytes::VERSION
  s.authors = ["Vladimir Dementyev"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/palkan/rbytes"
  s.summary = "Ruby Bytes is a tool to build application templates for Ruby and Rails applications"
  s.description = "Ruby Bytes is a tool to build application templates for Ruby and Rails applications"

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/rbytes/issues",
    "changelog_uri" => "https://github.com/palkan/rbytes/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/rbytes",
    "homepage_uri" => "http://github.com/palkan/rbytes",
    "source_code_uri" => "http://github.com/palkan/rbytes"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + Dir.glob("bin/**/*") + Dir.glob("templates/rbytes/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.0"

  s.add_dependency "thor"

  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake", ">= 13.0"
end
