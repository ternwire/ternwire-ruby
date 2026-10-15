require_relative "lib/ternwire/version"

Gem::Specification.new do |spec|
  spec.name = "ternwire"
  spec.version = Ternwire::VERSION
  spec.summary = "Ruby client for the Ternwire transactional email API"
  spec.authors = ["Ternwire"]
  spec.homepage = "https://ternwire.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "examples/*.rb"]
  spec.require_paths = ["lib"]
  spec.metadata["source_code_uri"] = "https://github.com/ternwire/ternwire-ruby"
  spec.metadata["documentation_uri"] = "https://ternwire.com/docs"
  spec.metadata["bug_tracker_uri"] = "https://ternwire.com/contact"
  spec.metadata["rubygems_mfa_required"] = "true"
end
