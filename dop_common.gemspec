# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dop_common/version'

Gem::Specification.new do |spec|
  spec.name          = "dop_common"
  spec.version       = DopCommon::VERSION
  spec.authors       = ["Andreas Zuber", "Pavol Dilung"]
  spec.email         = ["zuber@puzzle.ch", "pavol.dilung@swisscom.com"]
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

  spec.required_ruby_version = '>= 1.8.7'

  spec.add_development_dependency "bundler", "~> 1.3"

  if RUBY_VERSION <= '1.8.7'
    spec.add_development_dependency "rake", '~> 10.5'
  else
    spec.add_development_dependency "rake"
  end
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-legacy_formatters"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"

end
