# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "droplet/version"

Gem::Specification.new do |spec|
  spec.name        = "droplet"
  spec.version     = Droplet::VERSION
  spec.authors     = ["cj"]
  spec.email       = ["cjlazell@gmail.com"]

  spec.summary     = "Simple operations"
  spec.description = "Simple operations"
  spec.homepage    = "https://github.com/cj/droplet"
  spec.license     = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.1.14"
  spec.add_development_dependency "minitest-line", "~> 0.6.3"
  spec.add_development_dependency "rubocop", "~> 0.49.1"
  spec.add_development_dependency "dry-validation", "~> 0.10.7"
end
