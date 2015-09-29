# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dop_common/version'

Gem::Specification.new do |spec|
  spec.name          = "dop_common"
  spec.version       = DopCommon::VERSION
  spec.authors       = ["Andreas Zuber"]
  spec.email         = ["zuber@puzzle.ch"]
  spec.description   = <<-EOF
    This gem is part of the Deployment and Orchestration for Puppet
    or DOP for short. dop_common is a library for the parsing and
    validation of DOP plan files.
  EOF
  spec.summary       = %q{DOP plan file parser and validation library}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-legacy_formatters"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"

end
